//
//  AnyDirectusWebSocketSubscription.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

@MainActor
public protocol AnyDirectusWebSocketSubscription: Sendable {
    var uid: String { get }
    var onCreate: (([String: Any]) -> Void)? { get }
    var onUpdate: (([String: Any]) -> Void)? { get }
    var onDelete: (([String: Any]) -> Void)? { get }
    func toJson() -> [String: Any]
}
