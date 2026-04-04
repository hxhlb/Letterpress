//
//  Ext+Data.swift
//  Letterpress
//
//  Created by Rachel on 11/6/2025.
//

import Foundation

extension Data {
    func toHexColorString() -> String {
        var result: [String] = []
        var index = startIndex
        while index < endIndex {
            let nextIndex = index.advanced(by: 3)
            let chunk = self[index..<Swift.min(nextIndex, endIndex)]
            let hex = chunk.map { String(format: "%02X", $0) }.joined()
            result.append("#" + hex.padding(toLength: 6, withPad: "0", startingAt: 0))
            index = nextIndex
        }
        return result.joined(separator: ",")
    }

    init?(hexColorString: String) {
        let components = hexColorString.split(separator: ",")
        var data = Data()
        for comp in components {
            guard comp.hasPrefix("#"), comp.count == 7 else { return nil }
            let hex = comp.dropFirst()
            for i in stride(from: 0, to: hex.count, by: 2) {
                let start = hex.index(hex.startIndex, offsetBy: i)
                let end = hex.index(start, offsetBy: 2)
                let byteStr = hex[start..<end]
                guard let byte = UInt8(byteStr, radix: 16) else { return nil }
                data.append(byte)
            }
        }
        self = data
    }
}
