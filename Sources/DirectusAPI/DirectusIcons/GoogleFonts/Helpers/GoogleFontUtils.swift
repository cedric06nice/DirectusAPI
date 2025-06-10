//
//  GoogleFontUtils.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 09/06/2025.
//

struct GoogleFontUtils {
    static func idToName(_ id: UInt32) -> String {
        var str = ""
        for a in (0 ..< 4).reversed() {
            if let scalar = UnicodeScalar((id >> (a * 8)) & 0xFF) {
                str += String(Character(scalar))
            }
        }
        return str
    }
    
    static func nameToId(_ name: GoogleFontAxis.Name) -> UInt32 {
        nameToId(name.description)
    }
    
    static func nameToId(_ name: String) -> UInt32 {
        name.compactMap { $0.asciiValue }
            .reduce(UInt32(0)) { $0 << 8 | UInt32($1) }
    }
}
