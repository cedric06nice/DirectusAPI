//
//  MockCacheEngineTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 31/05/2025.
//

import Testing
import Foundation
@testable import DirectusAPI

// MARK: - Async Tests for MockCacheEngine
@MainActor
@Suite
struct MockCacheEngineAsyncTests {
    
    @Test
    func testGetCacheEntryReturnsExpectedValue() async throws {
        let mock = MockCacheEngine()
        let expected = CacheEntry(
            key: "test",
            dateCreated: Date(),
            validUntil: Date.distantFuture,
            headers: [:],
            body: "data",
            statusCode: 200
        )
        mock.returnQueue.append(expected)
        
        let result = try await mock.getCacheEntry(key: "test")
        #expect(result == expected)
        #expect(mock.calls.contains { $0.name == "getCacheEntry" && ($0.arguments["key"] as? String) == "test" })
    }
    
    @Test
    func testSetCacheEntryRecordsCall() async throws {
        let mock = MockCacheEngine()
        let expected = CacheEntry(
            key: "test",
            dateCreated: Date(),
            validUntil: Date.distantFuture,
            headers: [:],
            body: "data",
            statusCode: 200
        )
        let tags = ["tag1", "tag2"]
        
        try await mock.setCacheEntry(cacheEntry: expected, tags: tags)
        
        #expect(mock.calls.contains { $0.name == "setCacheEntry" })
    }
    
    @Test
    func testRemoveCacheEntryRecordsCall() async throws {
        let mock = MockCacheEngine()
        
        try await mock.removeCacheEntry(key: "key1")
        
        #expect(mock.calls.contains { $0.name == "removeCacheEntry" && ($0.arguments["key"] as? String) == "key1" })
    }
    
    @Test
    func testRemoveCacheEntriesWithTagRecordsCall() async throws {
        let mock = MockCacheEngine()
        
        try await mock.removeCacheEntriesWithTag(tag: "user")
        
        #expect(mock.calls.contains { $0.name == "removeCacheEntriesWithTag" && ($0.arguments["tag"] as? String) == "user" })
    }
    
    @Test
    func testClearCacheRecordsCall() async throws {
        let mock = MockCacheEngine()
        
        try await mock.clearCache()
        
        #expect(mock.calls.contains { $0.name == "clearCache" })
    }
    
    @Test
    func testGetCacheEntryEmptyReturnQueueThrows() async {
        let mock = MockCacheEngine()
        await #expect(throws: Error.self) {
            try await mock.getCacheEntry(key: "missing")
        }
    }
    
    @Test
    func testSetCacheEntryWithEmptyTags() async throws {
        let mock = MockCacheEngine()
        let expected = CacheEntry(
            key: "test-empty-tags",
            dateCreated: Date(),
            validUntil: Date.distantFuture,
            headers: [:],
            body: "empty",
            statusCode: 204
        )
        
        try await mock.setCacheEntry(cacheEntry: expected, tags: [])
        
        #expect(mock.calls.contains { $0.name == "setCacheEntry" && ($0.arguments["tags"] as? [String])?.isEmpty == true })
    }
    
    @Test
    func testRemoveCacheEntryWithEmptyKey() async throws {
        let mock = MockCacheEngine()
        
        try await mock.removeCacheEntry(key: "")
        
        #expect(mock.calls.contains { $0.name == "removeCacheEntry" && ($0.arguments["key"] as? String) == "" })
    }
    
    @Test
    func testRemoveCacheEntriesWithEmptyTag() async throws {
        let mock = MockCacheEngine()
        
        try await mock.removeCacheEntriesWithTag(tag: "")
        
        #expect(mock.calls.contains { $0.name == "removeCacheEntriesWithTag" && ($0.arguments["tag"] as? String) == "" })
    }
    
    @Test
    func testClearCacheTwice() async throws {
        let mock = MockCacheEngine()
        
        try await mock.clearCache()
        try await mock.clearCache()
        
        let count = mock.calls.filter { $0.name == "clearCache" }.count
        #expect(count == 2)
    }
}
