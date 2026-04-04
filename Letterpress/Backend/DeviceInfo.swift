//
//  DeviceInfo.swift
//  TRApp
//
//  Created by Lessica on 2024/3/3.
//

import Foundation

private let gestalt = MobileGestalt()

final class DeviceInfo {
    static let current = DeviceInfo()

    let udid: String
    let machine: String

    private init() {
#if targetEnvironment(simulator) || DEBUG
        let model = Self.getMachineModel()
        if model.hasPrefix("iPhone") {
            udid = "00000000-0000000000000000"
            machine = "iPhone16,2"
        } else {
            udid = "00000000-0000000000000000"
            machine = "iPad14,2"
        }
#else
        udid = gestalt.getValue(for: .uniqueDeviceID) ?? ""
        machine = gestalt.getValue(for: .productType) ?? ""
#endif
    }

    private static func getMachineModel() -> String {
#if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? ""
#else
        var size: Int = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        return String(cString: machine)
#endif
    }
}

private class MobileGestalt {
    enum Query: String {
        case uniqueDeviceID = "UniqueDeviceID"
        case productType = "ProductType"
    }

    typealias MGCopyAnswer = @convention(c) (CFString) -> CFTypeRef?
    let copyAnswerRef: MGCopyAnswer?
    let handle: UnsafeMutableRawPointer?

    init() {
        handle = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY)
        if let handleRef = handle,
           let sym = dlsym(handleRef, "MGCopyAnswer")
        {
            copyAnswerRef = unsafeBitCast(sym, to: MGCopyAnswer.self)
        } else {
            copyAnswerRef = nil
        }
    }

    deinit {
        guard let handleRef = handle else { return }
        dlclose(handleRef)
    }

    func getValue(for query: Query) -> String? {
        guard let mgc = copyAnswerRef else { return nil }
        let ref = mgc(query.rawValue as NSString)
        return cfStringer(ref)
    }

    func cfStringer(_ ref: CFTypeRef?) -> String? {
        guard let ref else { return nil }
        let typeID = CFGetTypeID(ref)

        if typeID == CFStringGetTypeID(),
           let iokString = ref as? String
        {
            return iokString
        }

        if typeID == CFBooleanGetTypeID(),
           let iokBool = ref as? Bool
        {
            return String(iokBool)
        }

        if typeID == CFNumberGetTypeID(),
           let iokNum = ref as? Int
        {
            return String(iokNum)
        }

        if typeID == CFDataGetTypeID(),
           let data = ref as? Data,
           let iokString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines)
        {
            return iokString
        }

        return nil
    }
}
