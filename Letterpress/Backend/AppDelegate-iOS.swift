//
//  AppDelegate.swift
//  Letterpress
//
//  Created by 秋星桥 on 5/29/25.
//

import UIKit

func registerUserDefaults() {
    var defaultsDict: [String: Any] = [:]
    if let settingsPath = Bundle.main.path(forResource: "Settings", ofType: "plist"),
       let settingsDict = NSDictionary(contentsOfFile: settingsPath) as? [String: Any],
       let itemsArray = settingsDict["items"] as? [[String: Any]]
    {
        for item in itemsArray {
            if let key = item["key"] as? String, let defaultValue = item["default"] {
                defaultsDict[key] = defaultValue
            }
        }
    }

    if let bundleIdentifier = Bundle.main.bundleIdentifier {
        CTService.grantNetworkingPermission(bundleIdentifier)
    }

    UserDefaults.standard.register(defaults: defaultsDict)
}

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        registerUserDefaults()
        _ = HudManager.shared
        return true
    }
}
