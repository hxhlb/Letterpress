//
//  HudManager.swift
//  Letterpress
//
//  Created by Rachel on 8/6/2025.
//

import Combine
import Foundation
import notify
import SwifterSwift
import SwiftUI

final class HudManager: ObservableObject {
    static let shared = HudManager()

    private var cancellables = Set<AnyCancellable>()

    private init() {
        defer {
            isNotifyBlocked = false
        }

        readColors()
        readFontType()
        readTokenizerMode()
        reloadHud()
    }

    fileprivate(set) var isHudEnabled: Bool = false
    fileprivate(set) var isNotifyBlocked: Bool = true

    @AppStorage("isEnabled")
    var isEnabled: Bool = true {
        didSet {
            reloadHud(notify: true)
        }
    }

    @AppStorage("fontType")
    private var fontType: String = HudViewModel.FontType.pingFang.rawValue {
        didSet {
            reloadHud(notify: true)
        }
    }

    @Published var selectedFont: HudViewModel.FontType = .pingFang {
        didSet {
            fontType = selectedFont.rawValue
        }
    }

    @AppStorage("tokenizerMode")
    private var tokenizerMode: String = HudViewModel.TokenizerMode.byCharacter.rawValue {
        didSet {
            reloadHud(notify: true)
        }
    }

    @Published var selectedTokenizerMode: HudViewModel.TokenizerMode = .byCharacter {
        didSet {
            tokenizerMode = selectedTokenizerMode.rawValue
        }
    }

    @AppStorage("widthRatio")
    var widthRatio: Double = 1.6 {
        didSet {
            reloadHud(notify: true)
        }
    }
    let minimumWidthRatio: Double = 1.0
    let maximumWidthRatio: Double = 2.0

    @AppStorage("yOffset")
    var yOffset: Double = 0.0 {
        didSet {
            reloadHud(notify: true)
        }
    }
    let minimumYOffset: Double = -160.0
    let maximumYOffset: Double = 100.0

    @AppStorage("ySlide")
    var ySlide: Double = -10.0 {
        didSet {
            reloadHud(notify: true)
        }
    }
    let minimumYSlide: Double = -32.0
    let maximumYSlide: Double = 32.0

    @AppStorage("fontSize")
    var fontSize: Double = 20.0 {
        didSet {
            reloadHud(notify: true)
        }
    }
    let minimumFontSize: Double = 8.0
    let maximumFontSize: Double = 44.0

    @AppStorage("birthRate")
    var birthRate: Double = 100.0 {
        didSet {
            reloadHud(notify: true)
        }
    }
    let minimumBirthRate: Double = 0.0
    let maximumBirthRate: Double = 200.0

    @AppStorage("lifespan")
    var lifespan: Double = 3.0 {
        didSet {
            reloadHud(notify: true)
        }
    }
    let minimumLifespan: Double = 1.0
    let maximumLifespan: Double = 10.0

    @AppStorage("speed")
    var speed: Double = 0.0 {
        didSet {
            reloadHud(notify: true)
        }
    }
    let minimumSpeed: Double = 0.0
    let maximumSpeed: Double = 1.0

    @AppStorage("speedVariation")
    var speedVariation: Double = 0.25 {
        didSet {
            reloadHud(notify: true)
        }
    }
    let minimumSpeedVariation: Double = 0.1
    let maximumSpeedVariation: Double = 1.0

    @AppStorage("burstCount")
    var burstCount: Double = 0.0 {
        didSet {
            reloadHud(notify: true)
        }
    }
    let minimumBurstCount: Double = 0.0
    let maximumBurstCount: Double = 200.0

    @AppStorage("burstCountVariation")
    var burstCountVariation: Double = 0.0 {
        didSet {
            reloadHud(notify: true)
        }
    }
    let minimumBurstCountVariation: Double = 0.0
    let maximumBurstCountVariation: Double = 200.0

    @AppStorage("attractionStrength")
    var attractionStrength: Double = -1.6 {
        didSet {
            reloadHud(notify: true)
        }
    }
    let minimumAttractionStrength: Double = -3.0
    let maximumAttractionStrength: Double = -0.1

    @AppStorage("dampingFactor")
    var dampingFactor: Double = 1.0 {
        didSet {
            reloadHud(notify: true)
        }
    }
    let minimumDampingFactor: Double = 0.0
    let maximumDampingFactor: Double = 5.0

    @AppStorage("initialSize")
    var initialSize: Double = 0.2 {
        didSet {
            reloadHud(notify: true)
        }
    }
    let minimumInitialSize: Double = 0.01
    let maximumInitialSize: Double = 1.0

    @AppStorage("sizeMultiplier")
    var sizeMultiplier: Double = 5.0 {
        didSet {
            reloadHud(notify: true)
        }
    }
    let minimumSizeMultiplier: Double = 1.0
    let maximumSizeMultiplier: Double = 100.0

    @AppStorage("opacity")
    var opacity: Double = 1.0 {
        didSet {
            reloadHud(notify: true)
        }
    }
    let minimumOpacity: Double = 0.0
    let maximumOpacity: Double = 1.0

    @AppStorage("color1")
    private var storedColor1 = "1.0,1.0,0.0,1.0"
    @AppStorage("color2")
    private var storedColor2 = "1.0,0.0,0.0,1.0"
    @AppStorage("color3")
    private var storedColor3 = "1.0,1.0,1.0,0.0"
    @AppStorage("color4")
    private var storedColor4 = "1.0,1.0,1.0,0.0"
    @AppStorage("tintColors")
    private var storedTintColors = String(String(repeating: "#FFFFFF,", count: 21).dropLast())

    @Published var color1: Color = .yellow
    @Published var color2: Color = .red
    @Published var color3: Color = .clear
    @Published var color4: Color = .clear
    @Published var tintColors: [Color] = []

    @AppStorage("isAdaptiveColorEnabled")
    var isAdaptiveColorEnabled: Bool = false {
        didSet {
            reloadHud(notify: true)
        }
    }

    @AppStorage("shouldDisplayOnLockScreen")
    var shouldDisplayOnLockScreen: Bool = false {
        didSet {
            reloadHud(notify: true)
        }
    }

    @AppStorage("shouldDisplayWhenScreencast")
    var shouldDisplayWhenScreencast: Bool = true {
        didSet {
            reloadHud(notify: true)
        }
    }

    @AppStorage("isLabelEnabled")
    var isLabelEnabled: Bool = false {
        didSet {
            reloadHud(notify: true)
        }
    }

    @AppStorage("labelFontSize")
    var labelFontSize: Double = 20.0 {
        didSet {
            reloadHud(notify: true)
        }
    }
    let minimumLabelFontSize: Double = 8.0
    let maximumLabelFontSize: Double = 44.0

    @AppStorage("yLabelOffset")
    var yLabelOffset: Double = 0.0 {
        didSet {
            reloadHud(notify: true)
        }
    }
    let minimumYLabelOffset: Double = -72.0
    let maximumYLabelOffset: Double = 72.0

    func reloadHud(notify: Bool = false) {
        if isCommandLineHud {
            return
        }
        if isEnabled {
            if !isHudEnabled {
                isHudEnabled = true

                HotspotHelperManager.shared.register("Letterpress")
                HotspotHelperManager.shared.isEnabled = true
            }

            showHud()
            if notify && !isNotifyBlocked {
                notify_post(LetterpressNotificationNameNeedsReload)
            }
        } else if !isEnabled && isHudEnabled {
            isHudEnabled = false
            HotspotHelperManager.shared.isEnabled = false

            hideHud()
        }
    }

    private lazy var marker: URL = {
        let markerName = String(format: "%@.hud.pid", Bundle.main.bundleIdentifier!)
        let markerURL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(
            .cachesDirectory, .userDomainMask, true).first!).appendingPathComponent(markerName)
        let bootTime = Date(timeIntervalSinceNow: -ProcessInfo.processInfo.systemUptime)
        if let attributes = try? FileManager.default.attributesOfItem(atPath: markerURL.path),
           let creationDate = attributes[.creationDate] as? Date,
           creationDate < bootTime {
            // Remove stale marker to avoid referencing a pre-boot process
            try? FileManager.default.removeItem(at: markerURL)
        }
        return markerURL
    }()

    private func showHud() {
        if let markerContent = FileManager.default.contents(atPath: marker.path),
           let pid = String(data: markerContent, encoding: .utf8)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
           !pid.isEmpty,
           let existingPid = Int32(pid),
           kill(existingPid, 0) == 0
        {
            // If the process is already running, do nothing.
            return
        }

        var outPid: pid_t = 0
        _ = Execute.spawn(
            binary: Bundle.main.executablePath!,
            arguments: ["-hud"],
            environment: ProcessInfo.processInfo.environment.merging([
                // "CG_NUMERICS_SHOW_BACKTRACE": "1",
                "DISABLE_TWEAKS": "1",
                "MARKER_PATH": marker.path,
            ]) { $1 },
            shouldUseRoot: false,
            shouldWait: false,
            outPid: &outPid
        )
    }

    private func hideHud() {
        notify_post(String(format: "%@.hud.dismissal", Bundle.main.bundleIdentifier!))
    }

    private func readColors() {
        color1 = parseColor(from: storedColor1)
        color2 = parseColor(from: storedColor2)
        color3 = parseColor(from: storedColor3)
        color4 = parseColor(from: storedColor4)
        let bgColors = storedTintColors
            .split(separator: ",")
            .compactMap { String($0).trimmingCharacters(in: .whitespaces) }
            .withoutDuplicates()
            .map { Color(hex: $0) }
        tintColors = bgColors
    }

    private func readFontType() {
        selectedFont = HudViewModel.FontType(rawValue: fontType) ?? .pingFang
    }

    private func readTokenizerMode() {
        selectedTokenizerMode = HudViewModel.TokenizerMode(rawValue: tokenizerMode) ?? .byCharacter
    }

    func saveColors() {
        storedColor1 = getRgbaString(from: color1)
        storedColor2 = getRgbaString(from: color2)
        storedColor3 = getRgbaString(from: color3)
        storedColor4 = getRgbaString(from: color4)
        storedTintColors = tintColors
            .compactMap { $0.toHex() }
            .map { "#\($0)" }
            .joined(separator: ",")
    }

    private func getRgbaString(from color: Color) -> String {
        if let cgColor = color.cgColor {
            if cgColor.numberOfComponents == 2 {
                let components = cgColor.components ?? [0, 0]
                return "\(components[0]),\(components[0]),\(components[0]),\(components[1])"
            } else if cgColor.numberOfComponents == 4 {
                let components = cgColor.components ?? [0, 0, 0, 1]
                return "\(components[0]),\(components[1]),\(components[2]),\(components[3])"
            }
        }
        return "0,0,0,0"
    }

    private func parseColor(from string: String) -> Color {
        let components = string.split(separator: ",").compactMap { Double($0) }
        guard components.count == 4 else { return .clear }
        return Color(red: components[0], green: components[1], blue: components[2], opacity: components[3])
    }

    func resetDefaults() {
        isNotifyBlocked = true
        defer {
            isNotifyBlocked = false
        }
        isEnabled = true
        fontType = HudViewModel.FontType.pingFang.rawValue
        tokenizerMode = HudViewModel.TokenizerMode.byCharacter.rawValue
        widthRatio = 1.6
        yOffset = 0.0
        ySlide = -10.0
        fontSize = 20.0
        birthRate = 100.0
        lifespan = 3.0
        speed = 0.0
        speedVariation = 0.25
        burstCount = 0.0
        burstCountVariation = 0.0
        attractionStrength = -1.6
        dampingFactor = 1.0
        initialSize = 0.2
        sizeMultiplier = 5.0
        opacity = 1.0
        storedColor1 = "1.0,1.0,0.0,1.0"
        storedColor2 = "1.0,0.0,0.0,1.0"
        storedColor3 = "1.0,1.0,1.0,0.0"
        storedColor4 = "1.0,1.0,1.0,0.0"
        isAdaptiveColorEnabled = false
        shouldDisplayOnLockScreen = false
        shouldDisplayWhenScreencast = true
        readColors()
        isLabelEnabled = false
        labelFontSize = 20.0
        yLabelOffset = 0.0
    }
}
