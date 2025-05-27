//
//  Dictionary+Extension.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

extension Dictionary where Key == AnyHashable, Value == Any {
    func compactMapKeys<T: Hashable>(_ transform: (Key) -> T?) -> [T: String] {
        var result = [T: String]()
        for (key, value) in self {
            if let newKey = transform(key) {
                result[newKey] = "\(value)"
            }
        }
        return result
    }
}
