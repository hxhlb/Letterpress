//
//  main.swift
//  Letterpress
//
//  Created by 秋星桥 on 5/29/25.
//

#if os(macOS)
import AppKit
#else
import TRHudObjC
#endif
import Foundation

#if os(macOS)
private let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
_ = NSApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv
)
#else

var eventProxy: HudEventProxy?
let isCommandLineHud = CommandLine.arguments.contains("-hud")
if isCommandLineHud {
    let delegate = TRHudMainApplicationDelegate()
    eventProxy = HudEventProxy(delegate: delegate)
    delegate.windowOrientationProxy = eventProxy
    delegate.viewControllerClassName = NSStringFromClass(HudContainerViewController.self)
    exit(TRHudMain(CommandLine.argc, CommandLine.unsafeArgv, delegate))
}

TRHudSetupSignalHandlers()
App.main()
#endif
