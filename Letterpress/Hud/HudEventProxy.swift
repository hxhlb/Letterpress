//
//  HudEventProxy.swift
//  Letterpress
//
//  Created by 82Flex on 6/4/25.
//

import Combine
import DominantColors
import notify
import SwiftUI
import TRHudObjC

final class HudEventProxy: NSObject, TRHudMainApplicationDelegateWindowOrientationProxy {

    let isAppInForeground: CurrentValueSubject<Bool, Never>
    let isHudVisible: CurrentValueSubject<Bool, Never>

    let isNowPlaying: CurrentValueSubject<Bool, Never>
    let nowPlayingApp: CurrentValueSubject<String?, Never>
    let nowPlayingSubtitle: CurrentValueSubject<String?, Never>

    @AppStorage("shouldDisplayOnLockScreen", store: HudViewModel.userDefaults)
    private var storedShouldDisplayOnLockScreen: Bool = false
    private var shouldDisplayOnLockScreen: Bool = false

    @AppStorage("shouldDisplayWhenScreencast", store: HudViewModel.userDefaults)
    private var storedShouldDisplayWhenScreencast: Bool = true
    private var shouldDisplayWhenScreencast: Bool = true

    @AppStorage("isAdaptiveColorEnabled", store: HudViewModel.userDefaults)
    private var storedIsAdaptiveColorEnabled: Bool = false
    private var isAdaptiveColorEnabled: Bool = false

    let mediaObserver: TRHudMediaObserver
    let nowPlayingArtworkColors: CurrentValueSubject<[Color]?, Never> = CurrentValueSubject(nil)
    weak var delegate: TRHudMainApplicationDelegate?

    init(delegate: TRHudMainApplicationDelegate) {
        self.delegate = delegate

        isAppInForeground = CurrentValueSubject(delegate.appMonitor.isPrimaryAppInForeground)
        isHudVisible = CurrentValueSubject(delegate.isVisible)
        isNowPlaying = CurrentValueSubject(false)

        nowPlayingApp = CurrentValueSubject(nil)
        nowPlayingSubtitle = CurrentValueSubject(nil)

        mediaObserver = TRHudMediaObserver()

        super.init()

        var token: Int32 = 0
        notify_register_dispatch(
            LetterpressNotificationNameNeedsReload,
            &token,
            DispatchQueue.main
        ) { [unowned self] _ in
            reloadUserDefaults()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appMonitorDidChange(_:)),
            name: NSNotification.Name.TRHudAppMonitorDidChange,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(visibilityDidChange(_:)),
            name: NSNotification.Name.TRHudVisibilityDidChange,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(mediaObserverDidChange(_:)),
            name: NSNotification.Name.TRHudMediaObserverDidChange,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(mediaObserverArtworkDidChange(_:)),
            name: NSNotification.Name.TRHudMediaObserverArtworkDidChange,
            object: nil
        )

        reloadUserDefaults()
    }

    private func reloadUserDefaults() {
        if shouldDisplayOnLockScreen != storedShouldDisplayOnLockScreen {
            shouldDisplayOnLockScreen = storedShouldDisplayOnLockScreen
            delegate?.shouldDisplayOnLockScreen = shouldDisplayOnLockScreen
        }
        if shouldDisplayWhenScreencast != storedShouldDisplayWhenScreencast {
            shouldDisplayWhenScreencast = storedShouldDisplayWhenScreencast
            delegate?.shouldHideWhenScreenRecording = !shouldDisplayWhenScreencast
        }
        isAdaptiveColorEnabled = storedIsAdaptiveColorEnabled
        mediaObserver.isArtworkDecodingRequired = isAdaptiveColorEnabled
        if !isAdaptiveColorEnabled {
            nowPlayingArtworkColors.send(nil)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setWindowOrientation(_ windowOrientation: UIInterfaceOrientation) {
    }

    @objc private func appMonitorDidChange(_ notification: Notification) {
        if let appMonitor = notification.object as? TRHudAppMonitor {
            isAppInForeground.send(appMonitor.isPrimaryAppInForeground)
        }
    }

    @objc private func visibilityDidChange(_ notification: Notification) {
        if let delegate = notification.object as? TRHudMainApplicationDelegate {
            isHudVisible.send(delegate.isVisible)
        }
    }

    @objc private func mediaObserverDidChange(_ notification: Notification) {
        if let mediaObserver = notification.object as? TRHudMediaObserver {
            isNowPlaying.send(mediaObserver.isNowPlaying)
            nowPlayingApp.send(mediaObserver.nowPlayingApp)
            nowPlayingSubtitle.send(mediaObserver.nowPlayingSubtitle)
        }
    }

    @objc private func mediaObserverArtworkDidChange(_ notification: Notification) {
        guard let mediaObserver = notification.object as? TRHudMediaObserver else {
            return
        }
        if let artworkImage = mediaObserver.nowPlayingArtwork {
            DispatchQueue.global(qos: .userInitiated).async {
#if DEBUG
                print("Decoding artwork image")
#endif
                guard let dominantColors = try? artworkImage.dominantColors(max: 4) else {
                    return
                }
                let convertedColors = dominantColors.map { Color($0) }
                DispatchQueue.main.async { [weak self] in
                    self?.nowPlayingArtworkColors.send(convertedColors + [.clear.opacity(0)])
                }
            }
        } else {
            nowPlayingArtworkColors.send(nil)
        }
    }
}
