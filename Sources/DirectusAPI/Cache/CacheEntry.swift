//
//  CacheEntry.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

@MainActor
public struct CacheEntry: Codable {
    public let key: String
    public let dateCreated: Date
    public let validUntil: Date
    public let headers: [String: String]
    public let body: String
    public let statusCode: Int
    
    // MARK: - Initializers
    
    public init(
        key: String,
        dateCreated: Date,
        validUntil: Date,
        headers: [String: String],
        body: String,
        statusCode: Int
    ) {
        self.key = key
        self.dateCreated = dateCreated
        self.validUntil = validUntil
        self.headers = headers
        self.body = body
        self.statusCode = statusCode
    }
    
    public init(
        from response: HTTPURLResponse,
        body: String,
        key: String,
        maxCacheAge: TimeInterval
    ) {
        let now = Date()
        self.key = key
        self.dateCreated = now
        self.validUntil = now.addingTimeInterval(maxCacheAge)
        self.headers = response.allHeaderFields.reduce(into: [String: String]()) { result, entry in
            if let key = entry.key as? String {
                result[key] = "\(entry.value)"
            }
        }
        self.body = body
        self.statusCode = response.statusCode
    }
    
    // MARK: - Convert to HTTPURLResponse-like (if needed)
    
    public func toURLResponse(url: URL) -> (HTTPURLResponse?, Data) {
        let data = Data(body.utf8)
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )
        return (response, data)
    }
}

extension CacheEntry: @preconcurrency Equatable {
    public static func == (lhs: CacheEntry, rhs: CacheEntry) -> Bool {
        lhs.key == rhs.key &&
        lhs.dateCreated == rhs.dateCreated &&
        lhs.validUntil == rhs.validUntil &&
        lhs.headers == rhs.headers &&
        lhs.body == rhs.body &&
        lhs.statusCode == rhs.statusCode
    }
}
