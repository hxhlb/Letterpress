//
//  Execute.swift
//  TRApp
//
//  Created by 秋星桥 on 2024/2/14.
//

import Foundation

@_silgen_name("posix_spawnattr_set_persona_np")
private func posix_spawnattr_set_persona_np(
    _ attr: UnsafeMutablePointer<posix_spawnattr_t?>,
    _ persona_id: uid_t,
    _ flags: UInt32
) -> Int32

@_silgen_name("posix_spawnattr_set_persona_uid_np")
private func posix_spawnattr_set_persona_uid_np(
    _ attr: UnsafeMutablePointer<posix_spawnattr_t?>,
    _ persona_id: uid_t
) -> Int32

@_silgen_name("posix_spawnattr_set_persona_gid_np")
private func posix_spawnattr_set_persona_gid_np(
    _ attr: UnsafeMutablePointer<posix_spawnattr_t?>,
    _ persona_id: uid_t
) -> Int32

private func WIFEXITED(_ status: Int32) -> Bool {
    _WSTATUS(status) == 0
}

private func _WSTATUS(_ status: Int32) -> Int32 {
    status & 0x7F
}

private func WIFSIGNALED(_ status: Int32) -> Bool {
    (_WSTATUS(status) != 0) && (_WSTATUS(status) != 0x7F)
}

private func WEXITSTATUS(_ status: Int32) -> Int32 {
    (status >> 8) & 0xFF
}

private func WTERMSIG(_ status: Int32) -> Int32 {
    status & 0x7F
}

private let POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE = UInt32(1)

enum Execute {
    @discardableResult
    static func spawn(
        binary: String,
        arguments: [String] = [],
        environment: [String: String] = [:],
        shouldUseRoot: Bool = true,
        shouldWait: Bool = false,
        outPid: inout pid_t
    ) -> Int32? {
        var attrs: posix_spawnattr_t?
        posix_spawnattr_init(&attrs)
        defer { posix_spawnattr_destroy(&attrs) }
        
        if shouldUseRoot {
            _ = posix_spawnattr_set_persona_np(&attrs, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE)
            _ = posix_spawnattr_set_persona_uid_np(&attrs, 0)
            _ = posix_spawnattr_set_persona_gid_np(&attrs, 0)
        }
        
        posix_spawnattr_setpgroup(&attrs, 0)
        posix_spawnattr_setflags(&attrs, Int16(POSIX_SPAWN_SETPGROUP))
        
        let env = environment
            .map { key, value in "\(key)=\(value)" }
            .reduce(into: [String]()) { $0.append($1) }
            .map { $0.withCString(strdup) }
        defer { env.forEach { free($0) } }
        
        let args = [binary] + arguments
        let argv: [UnsafeMutablePointer<CChar>?] = args.map { $0.withCString(strdup) }
        defer { for case let arg? in argv {
            free(arg)
        } }
        
        var pid: pid_t = 0
        let ret = posix_spawn(&pid, binary, nil, &attrs, argv + [nil], env + [nil])
        if ret != 0 {
            return nil
        }
        
        outPid = pid
        if shouldWait {
            var exitCode: Int32 = 0
            var waitResult: Int32 = 0
            
            repeat {
                waitResult = waitpid(pid, &exitCode, 0)
            } while waitResult == -1 && errno == EINTR
            
            if WIFSIGNALED(exitCode) {
                return nil
            }
            
            return WEXITSTATUS(exitCode)
        } else {
            var unused: Int32 = 0
            waitpid(pid, &unused, WNOHANG)
        }
        
        return nil
    }
}
