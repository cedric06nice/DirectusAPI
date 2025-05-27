//
//  JsonCacheEngineTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
@testable import DirectusAPI
import Foundation

@MainActor
struct JsonCacheEngineTests {
    let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("JsonCacheEngineTests")

    @Test func testSetAndGetCacheEntry() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        let engine = JsonCacheEngine(cacheFolderPath: tempDirectory.path)

        let entry = CacheEntry(
            key: "test-key",
            dateCreated: .now,
            validUntil: .now.addingTimeInterval(300),
            headers: ["Content-Type": "application/json"],
            body: "{\"data\": 123}",
            statusCode: 200
        )

        try await engine.setCacheEntry(cacheEntry: entry, tags: ["tag1", "tag2"])
        let loaded = try await engine.getCacheEntry(key: "test-key")

        #expect(loaded != nil)
        #expect(loaded?.key == entry.key)
        #expect(loaded?.body == entry.body)
        #expect(loaded?.headers == entry.headers)
        #expect(loaded?.statusCode == entry.statusCode)
    }

    @Test func testRemoveCacheEntry() async throws {
        let engine = JsonCacheEngine(cacheFolderPath: tempDirectory.path)
        let entry = CacheEntry(
            key: "delete-me",
            dateCreated: .now,
            validUntil: .now.addingTimeInterval(300),
            headers: [:],
            body: "delete",
            statusCode: 200
        )

        try await engine.setCacheEntry(cacheEntry: entry, tags: [])
        try await engine.removeCacheEntry(key: "delete-me")
        let loaded = try await engine.getCacheEntry(key: "delete-me")

        #expect(loaded == nil)
    }

    @Test func testRemoveCacheEntriesWithTag() async throws {
        let engine = JsonCacheEngine(cacheFolderPath: tempDirectory.path)

        let entry1 = CacheEntry(
            key: "tagged-entry-1",
            dateCreated: .now,
            validUntil: .now.addingTimeInterval(300),
            headers: [:],
            body: "entry1",
            statusCode: 200
        )
        let entry2 = CacheEntry(
            key: "tagged-entry-2",
            dateCreated: .now,
            validUntil: .now.addingTimeInterval(300),
            headers: [:],
            body: "entry2",
            statusCode: 200
        )

        try await engine.setCacheEntry(cacheEntry: entry1, tags: ["session"])
        try await engine.setCacheEntry(cacheEntry: entry2, tags: ["session"])

        try await engine.removeCacheEntriesWithTag(tag: "session")
        let loaded1 = try await engine.getCacheEntry(key: "tagged-entry-1")
        let loaded2 = try await engine.getCacheEntry(key: "tagged-entry-2")

        #expect(loaded1 == nil)
        #expect(loaded2 == nil)
    }

    @Test func testClearCache() async throws {
        let engine = JsonCacheEngine(cacheFolderPath: tempDirectory.path)

        let entry = CacheEntry(
            key: "clear-me",
            dateCreated: .now,
            validUntil: .now.addingTimeInterval(300),
            headers: [:],
            body: "data",
            statusCode: 200
        )

        try await engine.setCacheEntry(cacheEntry: entry, tags: [])
        try await engine.clearCache()
        let loaded = try await engine.getCacheEntry(key: "clear-me")

        #expect(loaded == nil)
    }
}
