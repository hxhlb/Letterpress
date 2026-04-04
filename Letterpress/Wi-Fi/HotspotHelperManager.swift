//
//  HotspotHelperManager.swift
//  NEHotspotHelperApp
//
//  Created by Daisuke T on 2019/01/08.
//  Copyright © 2019 Daisuke T. All rights reserved.
//

import Foundation
import NetworkExtension

/**
 * References:
 * https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/Hotspot_Network_Subsystem_Guide/
 */
final class HotspotHelperManager {
    static let shared = HotspotHelperManager()

    var hotspots = [Hotspot]()
    var isEnabled = false

    func register(_ displayName: String) {
        let options: [String: NSString] = [
            kNEHotspotHelperOptionDisplayName: displayName as NSString
        ]

        NEHotspotHelper.register(
            options: options,
            queue: .main
        ) { command in
            guard self.isEnabled else{
                return
            }

            self.handle(command: command)
        }
    }

    fileprivate func handle(command: NEHotspotHelperCommand) {
        if command.commandType == .none {
            handleOnNone(command: command)
        }
        else if command.commandType == .filterScanList {
            handleOnFilterScanList(command: command)
        }
        else if command.commandType == .evaluate {
            handleOnEvaluate(command: command)
        }
        else if command.commandType == .maintain {
            handleOnMaintain(command: command)
        }
        else if command.commandType == .authenticate {
            handleOnAuthenticate(command: command)
        }
        else if command.commandType == .presentUI {
            handleOnPresentUI(command: command)
        }
        else if command.commandType == .logoff {
            handleOnLogoff(command: command)
        }
    }

    fileprivate func handleOnNone(command: NEHotspotHelperCommand) {
    }

    fileprivate func handleOnFilterScanList(command: NEHotspotHelperCommand) {
        HudManager.shared.reloadHud()

        var array = [NEHotspotNetwork]()

        for network in command.networkList ?? [] {
            autoreleasepool {
                guard let index = hotspots.firstIndex(of: Hotspot(network: network)) else {
                    return
                }

                network.setPassword(hotspots[index].password)
                network.setConfidence(.high)

                array.append(network)
            }
        }

        let response = command.createResponse(.success)
        if array.count > 0 {
            response.setNetworkList(array)
        }

        response.deliver()
    }

    fileprivate func handleOnEvaluate(command: NEHotspotHelperCommand) {
        HudManager.shared.reloadHud()

        guard let network = command.network else {
            return
        }

        guard hotspots.contains(Hotspot(network: network)) else {
            return
        }

        network.setConfidence(.high)

        let response = command.createResponse(.success)
        response.setNetwork(network)
        response.deliver()
    }

    fileprivate func handleOnMaintain(command: NEHotspotHelperCommand) {
        guard let network = command.network else {
            return
        }

        guard hotspots.contains(Hotspot(network: network)) else {
            return
        }

        let response = command.createResponse(.success)
        response.setNetwork(network)
        response.deliver()
    }

    fileprivate func handleOnAuthenticate(command: NEHotspotHelperCommand) {
        guard let network = command.network else {
            return
        }

        guard hotspots.contains(Hotspot(network: network)) else {
            return
        }

        let response = command.createResponse(.success)
        response.setNetwork(network)
        response.deliver()
    }

    fileprivate func handleOnPresentUI(command: NEHotspotHelperCommand) {
    }

    fileprivate func handleOnLogoff(command: NEHotspotHelperCommand) {
    }
}
