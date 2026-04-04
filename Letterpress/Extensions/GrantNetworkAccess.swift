//
//  GrantNetworkAccess.swift
//  Reveil
//
//  Created by 秋星桥 on 2024/7/19.
//

import CoreFoundation
import Foundation

@_silgen_name("_CTServerConnectionCreate")
func _CTServerConnectionCreate(_ allocator: CFAllocator?, _ callback: (@convention(c) (CFTypeRef?, CFError?) -> Void)?, _ target: AnyObject?) -> CFTypeRef?

@_silgen_name("_CTServerConnectionSetCellularUsagePolicy")
@discardableResult
func _CTServerConnectionSetCellularUsagePolicy(_ connection: CFTypeRef, _ identifier: CFString, _ policies: CFDictionary) -> Int64

@_silgen_name("CFRelease")
func CFRelease(_ cf: CFTypeRef)

enum CTService {
    static let connection = _CTServerConnectionCreate(kCFAllocatorDefault, nil, nil)
    static func grantNetworkingPermission(_ bundleIdentifier: String) {
        guard let ctConnection = connection else { return }
        _CTServerConnectionSetCellularUsagePolicy(ctConnection, bundleIdentifier as CFString, [
            "kCTCellularDataUsagePolicy": "kCTCellularDataUsagePolicyAlwaysAllow",
            "kCTWiFiDataUsagePolicy": "kCTCellularDataUsagePolicyAlwaysAllow",
        ] as CFDictionary)
    }
}
