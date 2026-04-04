//
//  Hotspot.swift
//  NEHotspotHelperApp
//
//  Created by Daisuke T on 2019/01/08.
//  Copyright © 2019 Daisuke T. All rights reserved.
//

import Foundation
import NetworkExtension

class Hotspot: Equatable {

    enum AuthType: UInt {
        case WEP = 0
        case WPA = 1
    }

    var bssid: String
    var ssid: String
    var password: String
    var authType: AuthType

    init() {
        bssid = ""
        ssid = ""
        password = ""
        authType = AuthType.WEP
    }

    init(network: NEHotspotNetwork) {
        bssid = network.bssid
        ssid = network.ssid
        password = ""
        authType = AuthType.WEP
    }

    static func ==(lhs: Hotspot, rhs: Hotspot) -> Bool {

        if lhs.bssid.count > 0 && rhs.bssid.count > 0 {
            return lhs.bssid.caseInsensitiveCompare(rhs.bssid) == .orderedSame
        }

        return lhs.ssid.caseInsensitiveCompare(rhs.ssid) == .orderedSame
    }

    var description: String {
        return String(format: "BSSID[%@] SSID[%@]", bssid, ssid)
    }
}
