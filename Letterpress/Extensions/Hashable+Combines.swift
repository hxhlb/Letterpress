//
//  Hashable+Combines.swift
//  Letterpress
//
//  Created by Rachel on 9/6/2025.
//

func combines(_ value: any Hashable ...) -> Int {
    var hasher = Hasher()
    for v in value {
        hasher.combine(v)
    }
    return hasher.finalize()
}
