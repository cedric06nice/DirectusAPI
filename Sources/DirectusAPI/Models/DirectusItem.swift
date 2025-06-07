//
//  DirectusItem.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

@MainActor
class DirectusItem: DirectusData {
    required init(_ rawReceivedData: [String: Any]) throws {
        try super.init(rawReceivedData)
    }
    
    static func from(data: [String: Any]) throws -> DirectusItem? {
        try DirectusItem(data)
    }
    
    static func new() throws -> DirectusItem {
        guard let item = try DirectusItem.from(data: ["id": UUID().uuidString]) else {
            throw NSError(domain: "DirectusItem", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create new DirectusItem"])
        }
        return item
    }
    
    func withId(_ id: Any) throws -> DirectusItem {
        guard let item = try DirectusItem.from(data: ["id": id]) else {
            throw NSError(domain: "DirectusItem", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create DirectusItem with ID"])
        }
        return item
    }
}
