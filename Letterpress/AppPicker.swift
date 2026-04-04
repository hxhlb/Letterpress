//
//  AppPicker.swift
//  Letterpress
//
//  Created by Rachel on 9/6/2025.
//

import SwiftUI

struct AppPicker: UIViewControllerRepresentable {
    class Coordinator {
        var parentObserver: NSKeyValueObservation?
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = AppPickerController(nibName: nil, bundle: nil)
        if let bundlePath = Bundle.main.path(forResource: "AltList", ofType: "framework", inDirectory: "Frameworks"),
           let bundle = Bundle(path: bundlePath)
        {
            viewController.setValue(bundle, forKey: "_altListBundle")
        }
        let specifiers = viewController.loadSpecifiers(fromPlistName: "Settings", target: viewController)
        viewController.replaceSpecifier = specifiers?.lastObject as? PSSpecifier
        context.coordinator.parentObserver = viewController.observe(\.parent, changeHandler: { vc, _ in
            vc.parent?.title = NSLocalizedString("Selected Applications", comment: "")
            vc.parent?.navigationItem.searchController = vc.navigationItem.searchController
            vc.parent?.navigationItem.rightBarButtonItems = vc.navigationItem.rightBarButtonItems
        })
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No update needed
    }

    func makeCoordinator() -> Self.Coordinator { Coordinator() }
}

final class AppPickerController: ATLApplicationListMultiSelectionController {
    var replaceSpecifier: PSSpecifier!

    override var specifier: PSSpecifier! {
        get {
            return replaceSpecifier
        }
        set {
            replaceSpecifier = newValue
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @objc override func savePreferences() {
        super.savePreferences()
        HudManager.shared.reloadHud(notify: true)
    }
}
