//
//  HudViewController.swift
//  TRApp
//
//  Created by 秋星桥 on 2024/2/15.
//

import SwiftUI

final class HudViewController: UIHostingController<HudContentView> {
    init() {
        super.init(rootView: .init())
        self._setSecurityModeForViewsLayer()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc(_canShowWhileLocked)
    public func _canShowWhileLocked() -> Bool {
        return true
    }
}
