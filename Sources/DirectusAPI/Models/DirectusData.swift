//
//  DirectusData.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

@MainActor
open class DirectusData {
    private var _rawReceivedData: [String: Any]
    public var updatedProperties: [String: Any] = [:]
    
    public required init(_ rawReceivedData: [String: Any]) throws {
        guard rawReceivedData["id"] != nil else {
            throw NSError(domain: "DirectusData", code: 1, userInfo: [NSLocalizedDescriptionKey: "id is required"])
        }
        self._rawReceivedData = rawReceivedData
        
//        // 🔐 Auto-register metadata if subclass conforms
//        if let selfType = type(of: self) as? any DirectusCollection.Type {
//            CollectionMetadataRegistry
//                .register(selfType, metadata: selfType.collectionMetadata)
//        }
    }
    
    func newDirectusData(rawReceivedData: [String: Any] = [:]) {
        self._rawReceivedData = rawReceivedData
    }
    
    public static func withId(_ id: Any) throws -> DirectusData {
        return try DirectusData(["id": id])
    }
    
    public var userCreated: String? {
        if let userCreated = getValue(forKey: "user_created") {
            return "\(userCreated)"
        }
        return nil
    }
    
    public func userCreated(value: String?) {
        setValue(value, forKey: "user_created")
    }
    
    public func getValue(forKey key: String) -> Any? {
        return updatedProperties[key] ?? _rawReceivedData[key]
    }
    
    public func setValue(_ value: Any?, forKey key: String) {
        if let current = getValue(forKey: key), "\(String(describing: current))" == "\(String(describing: value))" {
            return
        }
        updatedProperties[key] = value
    }
    
    public var id: String? {
        if let id = getValue(forKey: "id") {
            return "\(id)"
        }
        return nil
    }
    
    public var intId: Int? {
        return getValue(forKey: "id") as? Int
    }
    
    public func getRawData() -> [String: Any] {
        return _rawReceivedData
    }
    
    public var needsSaving: Bool {
        return !updatedProperties.isEmpty
    }
    
    public func hasChangedIn(forKey key: String) -> Bool {
        return updatedProperties.keys.contains(key)
    }
    
    func getDirectusFile(forKey key: String) async -> DirectusFile {
        guard let file = await getOptionalDirectusFile(forKey: key) else {
            fatalError("Expected file for key \(key)")
        }
        return file
    }
    
    func getOptionalDirectusFile(forKey key: String) async -> DirectusFile? {
        if let dict = getValue(forKey: key) as? [String: Any] {
            return try? DirectusFile(dict)
        } else if let id = getValue(forKey: key) as? String {
            return try? DirectusFile.fromId(id)
        }
        return nil
    }
    
    func setOptionalDirectusFile(_ file: DirectusFile?, forKey key: String) {
        setValue(file?.id, forKey: key)
    }
    
    public func getList<T>(forKey key: String) -> [T] {
        guard let rawList = getValue(forKey: key) as? [Any] else { return [] }
        return rawList.compactMap { $0 as? T }
    }
    
    public func getObjectList<T>(forKey key: String, fromMap: ([String: Any]) -> T) -> [T] {
        guard let list = getValue(forKey: key) as? [[String: Any]] else { return [] }
        return list.map(fromMap)
    }
    
    public func getOptionalDateTime(forKey key: String) -> Date? {
        let value = getValue(forKey: key)
        if let date = value as? Date {
            return date
        } else if let string = value as? String {
            return ISO8601DateFormatter().date(from: string) ?? DateFormatter().date(from: string)
        }
        return nil
    }
    
    public func getDateTime(forKey key: String) -> Date {
        guard let date = getOptionalDateTime(forKey: key) else {
            fatalError("Missing date for key \(key)")
        }
        return date
    }
    
    public func setOptionalDateTime(_ value: Date?, forKey key: String) {
        if let value = value {
            setValue(ISO8601DateFormatter().string(from: value), forKey: key)
        } else {
            setValue(nil, forKey: key)
        }
    }
    
    func getDirectusGeometryType(forKey key: String) -> DirectusGeometryType {
        guard let geometry = getOptionalDirectusGeometryType(forKey: key) else {
            fatalError("Missing geometry for key \(key)")
        }
        return geometry
    }
    
    func getOptionalDirectusGeometryType(forKey key: String) -> DirectusGeometryType? {
        guard let map = getValue(forKey: key) as? [String: Any] else { return nil }
        return DirectusGeometryType.fromJSON(map)
    }
    
    public func toMap() -> [String: Any] {
        return _rawReceivedData.merging(updatedProperties) { _, new in new }
    }
    
    public func mapForObjectCreation() -> [String: Any] {
        var map = toMap()
        map.removeValue(forKey: "id")
        return map
    }
}
