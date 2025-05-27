//
//  CacheEntryTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
@testable import DirectusAPI
import Foundation

@MainActor
struct CacheEntryTests {
    @Test func testInitFromHTTPURLResponse() throws {
        let url = URL(string: "https://example.com/data")!
        let bodyString = "{\"key\": \"value\"}"
        let key = "cache-key"
        let headers = ["Content-Type": "application/json", "Cache-Control": "max-age=3600"]

        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: headers
        )!

        let entry = CacheEntry(from: response, body: bodyString, key: key, maxCacheAge: 3600)

        #expect(entry.key == key)
        #expect(entry.body == bodyString)
        #expect(entry.statusCode == 200)
        #expect(entry.headers["Content-Type"] == "application/json")
        #expect(entry.validUntil.timeIntervalSince(entry.dateCreated) > 3590)
    }

    @Test func testToURLResponse() throws {
        let url = URL(string: "https://example.com")!
        let originalHeaders = ["Content-Type": "application/json"]
        let entry = CacheEntry(
            key: "test-key",
            dateCreated: .now,
            validUntil: .now.addingTimeInterval(600),
            headers: originalHeaders,
            body: "Test body",
            statusCode: 201
        )

        let (response, data) = entry.toURLResponse(url: url)

        #expect(response != nil)
        #expect(response?.statusCode == 201)
        #expect(response?.url == url)
        #expect(data == Data("Test body".utf8))
    }
    
    @Test func testJSONEncodingDecoding() throws {
        let entry = CacheEntry(
            key: "json-test",
            dateCreated: .now,
            validUntil: .now.addingTimeInterval(120),
            headers: ["Authorization": "Bearer token"],
            body: "{\"data\":\"sample\"}",
            statusCode: 200
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entry)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(CacheEntry.self, from: data)
        
        #expect(decoded.key == entry.key)
        #expect(decoded.body == entry.body)
        #expect(decoded.statusCode == entry.statusCode)
        #expect(decoded.headers == entry.headers)
    }
    
    @Test func testSaveAndLoadFromFile() throws {
        let entry = CacheEntry(
            key: "file-test",
            dateCreated: .now,
            validUntil: .now.addingTimeInterval(300),
            headers: ["Accept": "application/json"],
            body: "Cached response body",
            statusCode: 200
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entry)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("cache_entry_test.json")
        try data.write(to: tempURL)
        
        let loadedData = try Data(contentsOf: tempURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let loadedEntry = try decoder.decode(CacheEntry.self, from: loadedData)
        
        #expect(loadedEntry.key == entry.key)
        #expect(loadedEntry.body == entry.body)
        #expect(loadedEntry.headers == entry.headers)
        #expect(loadedEntry.statusCode == entry.statusCode)
        #expect(abs(loadedEntry.dateCreated.timeIntervalSince(entry.dateCreated)) < 1)
        #expect(abs(loadedEntry.validUntil.timeIntervalSince(entry.validUntil)) < 1)
        
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    @Test func testCacheExpiration() throws {
        let now = Date()
        let expiredEntry = CacheEntry(
            key: "expired",
            dateCreated: now.addingTimeInterval(-300),
            validUntil: now.addingTimeInterval(-100),
            headers: [:],
            body: "",
            statusCode: 200
        )
        
        let validEntry = CacheEntry(
            key: "valid",
            dateCreated: now,
            validUntil: now.addingTimeInterval(300),
            headers: [:],
            body: "",
            statusCode: 200
        )
        
        #expect(expiredEntry.validUntil < Date())
        #expect(validEntry.validUntil > Date())
    }
}
