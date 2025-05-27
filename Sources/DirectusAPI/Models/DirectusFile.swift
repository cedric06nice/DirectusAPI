//
//  DirectusFile.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

@MainActor
public final class DirectusFile: DirectusData {
    static var baseUrl: String?
    
    var title: String? {
        getValue(forKey: "title") as? String
    }
    
    var type: String? {
        getValue(forKey: "type") as? String
    }
    
    var uploadedOn: Date? {
        getOptionalDateTime(forKey: "uploaded_on")
    }
    
    var fileSize: Int? {
        getValue(forKey: "filesize") as? Int
    }
    
    var width: Int? {
        getValue(forKey: "width") as? Int
    }
    
    var height: Int? {
        getValue(forKey: "height") as? Int
    }
    
    var duration: Int? {
        getValue(forKey: "duration") as? Int
    }
    
    var descriptionText: String? {
        getValue(forKey: "description") as? String
    }
    
    var metadata: [String: Any]? {
        getValue(forKey: "metadata") as? [String: Any]
    }
    
    var ratio: Double {
        guard let width = width, let height = height, height != 0 else {
            return 1.0
        }
        return Double(width) / Double(height)
    }
    
    required init(_ rawReceivedData: [String: Any]) throws {
        try super.init(rawReceivedData)
    }
    
    static func fromId(_ id: String, title: String? = nil) throws -> DirectusFile {
        return try DirectusFile(["id": id, "title": title as Any])
    }
    
    func getDownloadURL(width: Int? = nil, height: Int? = nil, quality: Int? = nil, otherKeys: [String: String] = [:]) -> String {
        guard let baseUrl = DirectusFile.baseUrl, let id = self.id else {
            fatalError("baseURL or id not set")
        }
        
        var components = URLComponents(string: "\(baseUrl)/assets/\(id)")!
        var queryItems: [URLQueryItem] = []
        
        if let width = width {
            queryItems.append(URLQueryItem(name: "width", value: "\(width)"))
        }
        if let height = height {
            queryItems.append(URLQueryItem(name: "height", value: "\(height)"))
        }
        if let quality = quality {
            queryItems.append(URLQueryItem(name: "quality", value: "\(quality)"))
        }
        
        for (key, value) in otherKeys {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        return components.url!.absoluteString
    }
}

extension DirectusFile: @preconcurrency Equatable {
    
    public static func == (lhs: DirectusFile, rhs: DirectusFile) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title
    }
}

extension DirectusFile: @preconcurrency Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
    }
}

extension DirectusFile: @preconcurrency Codable {
    
    enum CodingKeys: String, CodingKey {
        case id, title, type, uploadedOn = "uploaded_on", fileSize = "filesize"
        case width, height, duration, descriptionText = "description", metadata
    }
    
    // MARK: - Codable
    convenience public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var dict: [String: Any] = [:]
        
        if let id = try container.decodeIfPresent(String.self, forKey: .id) {
            dict["id"] = id
        }
        dict["title"] = try container.decodeIfPresent(String.self, forKey: .title)
        dict["type"] = try container.decodeIfPresent(String.self, forKey: .type)
        if let uploaded = try container.decodeIfPresent(Date.self, forKey: .uploadedOn) {
            dict["uploaded_on"] = ISO8601DateFormatter().string(from: uploaded)
        }
        dict["filesize"] = try container.decodeIfPresent(Int.self, forKey: .fileSize)
        dict["width"] = try container.decodeIfPresent(Int.self, forKey: .width)
        dict["height"] = try container.decodeIfPresent(Int.self, forKey: .height)
        dict["duration"] = try container.decodeIfPresent(Int.self, forKey: .duration)
        dict["description"] = try container.decodeIfPresent(String.self, forKey: .descriptionText)
        dict["metadata"] = try container.decodeIfPresent([String: CodableValue].self, forKey: .metadata)
        
        try self.init(dict)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(uploadedOn, forKey: .uploadedOn)
        try container.encodeIfPresent(fileSize, forKey: .fileSize)
        try container.encodeIfPresent(width, forKey: .width)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(descriptionText, forKey: .descriptionText)
        if let metadata = metadata {
            let _ = try JSONSerialization.data(withJSONObject: metadata)
            let codableMetadata = metadata.mapValues { CodableValue(any: $0) }
            try container.encodeIfPresent(codableMetadata, forKey: .metadata)
        }
    }
}
