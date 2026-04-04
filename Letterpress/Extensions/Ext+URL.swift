//
//  Ext+URL.swift
//  Letterpress
//
//  Created by Rachel on 11/6/2025.
//

import Foundation

extension URL {
    func entitlementValue(name: String) throws -> Data {
        let path = self.path
        let length = getxattr(path, name, nil, 0, 0, 0)
        guard length >= 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
        var data = Data(count: length)
        let result = data.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) -> Int in
            return getxattr(path, name, ptr.baseAddress, length, 0, 0)
        }
        guard result >= 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
        return data
    }

    func setEntitlementValue(name: String, value: Data) throws {
        let path = self.path
        let result = value.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Int32 in
            return setxattr(path, name, ptr.baseAddress, value.count, 0, 0)
        }
        guard result == 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
    }
}
