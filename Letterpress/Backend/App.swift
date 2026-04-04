//
//  App.swift
//  Letterpress
//
//  Created by Rachel on 8/6/2025.
//

import SwiftUI

struct App: SwiftUI.App {
    @Environment(\.scenePhase) var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                HudManager.shared.reloadHud()
            }
        }
    }
}
