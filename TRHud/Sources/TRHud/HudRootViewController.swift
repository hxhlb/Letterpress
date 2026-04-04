//
//  HUDRootViewController.swift
//  TRApp
//
//  Created by Lessica on 2024/2/13.
//

import Combine
import notify
import TRHudObjC
import SwiftUI
import UIKit

@objc(TRHudRootViewController)
final class HudRootViewController: UIViewController {
    private let controller: UIViewController

    private var invisibleContainerView: ScreenshotInvisibleContainer?

    private var reloadToken = Int32(0)
    private var cancellables = Set<AnyCancellable>()

    private lazy var applicationDelegate = UIApplication.shared.delegate as? TRHudMainApplicationDelegate

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        guard let appDelegate = UIApplication.shared.delegate as? TRHudMainApplicationDelegate,
              let viewControllerName = appDelegate.viewControllerClassName
        else {
            fatalError("View controller class name not set in application delegate.")
        }
        guard let viewControllerClass = NSClassFromString(viewControllerName) as? UIViewController.Type
        else {
            fatalError("Unable to find view controller class: \(viewControllerName)")
        }
        self.controller = viewControllerClass.init()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        appDelegate.screenshotInvisibleProxy = self
        self._setSecurityModeForViewsLayer()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = []
        controller.view.backgroundColor = .clear
        controller.edgesForExtendedLayout = []
        invisibleContainerView = ScreenshotInvisibleContainer(content: controller.view)
        if let hiddenContainer = invisibleContainerView?.hiddenContainer {
            hiddenContainer.translatesAutoresizingMaskIntoConstraints = false
            addChild(controller)
            view.addSubview(hiddenContainer)
            controller.didMove(toParent: self)
            hiddenContainer.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            hiddenContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            hiddenContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            hiddenContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        }
        if let applicationDelegate {
            setScreenshotInvisible(applicationDelegate.shouldHideWhenScreenRecording)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        controller.view.frame = view.bounds
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    @objc(_canShowWhileLocked)
    public func _canShowWhileLocked() -> Bool {
        return true
    }
}

extension HudRootViewController: TRHudScreenshotInvisibleProxy {
    func setScreenshotInvisible(_ screenshotInvisible: Bool) {
        if screenshotInvisible {
            invisibleContainerView?.setupContainerAsHideContentInScreenshots()
        } else {
            invisibleContainerView?.setupContainerAsDisplayContentInScreenshots()
        }
    }
}
