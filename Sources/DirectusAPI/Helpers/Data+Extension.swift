//
//  Data+Extension.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        } else {
            fatalError("Unable to convert string to UTF-8 data")
        }
    }
}
