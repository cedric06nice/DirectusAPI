//
//  DirectusWebSocketSubscription.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

@MainActor
public final class DirectusWebSocketSubscription<T: DirectusData & DirectusCollection> {
    public let fields: [String]?
    public let filter: Filter?
    public let sort: [SortProperty]?
    public let uid: String
    public let limit: Int?
    public let offset: Int?

    public var onCreate: (([String: Any]) -> Void)?
    public var onUpdate: (([String: Any]) -> Void)?
    public var onDelete: (([String: Any]) -> Void)?
    
    public var collectionMetadata: CollectionMetadata {
        _collectionMetadata(for: T.self)
    }

    public var collection: String {
        T.collectionMetadata.endpointName
    }

    public init(
        uid: String,
        fields: [String]? = nil,
        filter: Filter? = nil,
        sort: [SortProperty]? = nil,
        limit: Int? = nil,
        offset: Int? = nil,
        onCreate: (([String: Any]) -> Void)? = nil,
        onUpdate: (([String: Any]) -> Void)? = nil,
        onDelete: (([String: Any]) -> Void)? = nil
    ) {
        guard onCreate != nil || onUpdate != nil || onDelete != nil else {
            fatalError("You must provide at least one callback for onCreate, onUpdate or onDelete")
        }

        self.uid = uid
        self.fields = fields
        self.filter = filter
        self.sort = sort
        self.limit = limit
        self.offset = offset
        self.onCreate = onCreate
        self.onUpdate = onUpdate
        self.onDelete = onDelete
    }

    public func toJson() -> String {
        var result: [String: Any] = [
            "type": "subscribe",
            "collection": T.collectionMetadata.webSocketEndpoint
        ]

        var query: [String: Any] = [
            "fields": fieldsToJson
        ]

        if let filter = filter {
            query["filter"] = filter.asDictionary
        }

        if let sort = sort, !sort.isEmpty {
            query["sort"] = sort.map { $0.ascending ? $0.name : "-\($0.name)" }
        }

        if let limit = limit {
            query["limit"] = limit
        }

        if let offset = offset {
            query["offset"] = offset
        }

        result["query"] = query

        let jsonData = try? JSONSerialization.data(withJSONObject: result, options: [])
        let jsonString = jsonData.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        return jsonString.replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: " ", with: "")
    }

    private var fieldsToJson: [String] {
        fields ?? T.collectionMetadata.defaultFields.split(separator: ",").map(String.init)
    }
    
    public var filterToJson: [String: Any]? {
        filter?.asDictionary
    }
    
    private func _collectionMetadata(for type: T.Type) -> CollectionMetadata {
        guard let metadata = CollectionMetadataRegistry.metadata(for: type) else {
            fatalError("No CollectionMetadata registered for \(type)")
        }
        return metadata
    }
}
