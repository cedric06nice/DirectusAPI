//
//  CollectionMetadata.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

/// Marker protocol to annotate types that represent Directus collections.
/// CollectionMetadataRegistry.register(User.self, metadata: ...)
/// guard let type = T.self as? any DirectusCollection.Type else {
///    throw MetadataError("Type \(T.self) does not conform to DirectusCollection")
/// }
/// let metadata = type.collectionMetadata
@MainActor
public protocol DirectusCollection {
    static var collectionMetadata: CollectionMetadata { get }
}

/// Metadata for a Directus collection.
@MainActor
public struct CollectionMetadata {
    public let endpointName: String
    public let endpointPrefix: String
    public let defaultFields: String
    public let webSocketEndPoint: String?
    public let defaultUpdateFields: String?

    public init(
        endpointName: String,
        defaultFields: String = "*",
        endpointPrefix: String = "/items/",
        webSocketEndPoint: String? = nil,
        defaultUpdateFields: String? = nil
    ) {
        self.endpointName = endpointName
        self.defaultFields = defaultFields
        self.endpointPrefix = endpointPrefix
        self.webSocketEndPoint = webSocketEndPoint
        self.defaultUpdateFields = defaultUpdateFields
    }

    public var webSocketEndpoint: String {
        return webSocketEndPoint ?? endpointName
    }
}

/// Global registry for mapping types to metadata
@MainActor
public enum CollectionMetadataRegistry {
    private static var registry: [ObjectIdentifier: CollectionMetadata] = [:]
    
    public static func register<T: DirectusCollection>(_ type: T.Type) {
        let id = ObjectIdentifier(type)
        registry[id] = T.collectionMetadata
    }
    
    public static func metadata<T: DirectusCollection>(for type: T.Type) -> CollectionMetadata? {
        let id = ObjectIdentifier(type)
        return registry[id]
    }
    
    public static func metadata(for instance: DirectusCollection) -> CollectionMetadata? {
        let id = ObjectIdentifier(type(of: instance))
        return registry[id]
    }
}
