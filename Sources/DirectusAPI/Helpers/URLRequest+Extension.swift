//
//  URLRequest+Extension.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

public extension URLRequest {
    mutating func addJsonHeaders() {
        self.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
}
