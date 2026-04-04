//
//  ScreenshotInvisibleContainer.swift
//
//
//  Created by Князьков Илья on 01.03.2022.
//

import UIKit

@objc
class ScreenshotInvisibleContainer: UITextField {
    // MARK: - Private Properties

    private let hiddenContainerRecognizer = HiddenContainerRecognizer()

    @objc
    var hiddenContainer: UIView? {
        try? hiddenContainerRecognizer.getHiddenContainer(from: self)
    }

    // MARK: - Internal Properties

    /// - View, which will be hidden on screenshots and screen recording
    private(set) var content: UIView

    // MARK: - Initialization

    @objc
    init(content: UIView) {
        self.content = content
        super.init(frame: .zero)
        setupInitialState()
    }

    @objc
    required init?(coder: NSCoder) {
        content = UIView()
        super.init(coder: coder)
        setupInitialState()
    }

    // MARK: - UIView

    override var canBecomeFocused: Bool {
        false
    }

    override var canBecomeFirstResponder: Bool {
        false
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        hiddenContainer?.hitTest(point, with: event)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        isUserInteractionEnabled = content.isUserInteractionEnabled
    }

    // MARK: - Private methods

    private func setupInitialState() {
        appendContent(to: hiddenContainer)

        backgroundColor = .clear
        isUserInteractionEnabled = content.isUserInteractionEnabled
    }

    private func activateLayoutConstraintsOfContent(to view: UIView) {
        [
            content.topAnchor.constraint(equalTo: view.topAnchor),
            content.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ].forEach { $0.isActive = true }
    }

    private func appendContent(to view: UIView?) {
        guard let view else {
            return
        }
        view.addSubview(content)
        view.isUserInteractionEnabled = true
        content.translatesAutoresizingMaskIntoConstraints = false
        activateLayoutConstraintsOfContent(to: view)
    }
}

// MARK: - ScreenshotInvisibleContainerProtocol

@objc
extension ScreenshotInvisibleContainer: ScreenshotInvisibleContainerProtocol {
    func eraseOldAndAddNewContent(_ newContent: UIView) {
        content.removeFromSuperview()
        content = newContent
        appendContent(to: hiddenContainer)
    }

    func setupContainerAsHideContentInScreenshots() {
        isSecureTextEntry = true
    }

    func setupContainerAsDisplayContentInScreenshots() {
        isSecureTextEntry = false
    }
}
