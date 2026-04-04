//
//  ScreenshotInvisibleContainerProtocol.swift
//
//
//  Created by Князьков Илья on 02.03.2022.
//

import UIKit

protocol ScreenshotInvisibleContainerProtocol: UIView {
    func eraseOldAndAddNewContent(_ newContent: UIView)
    func setupContainerAsHideContentInScreenshots()
    func setupContainerAsDisplayContentInScreenshots()
}
