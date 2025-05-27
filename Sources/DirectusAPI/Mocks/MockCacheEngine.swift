//
//  MockCacheEngine.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

@MainActor
public final class MockCacheEngine: LocalDirectusCacheProtocol {
    public init() {}

    public private(set) var calls: [(name: String, arguments: [String: Any])] = []
    public var returnQueue: [Any] = []

    private func recordCall(_ name: String, arguments: [String: Any] = [:]) {
        calls.append((name, arguments))
    }

    private func nextReturn<T>() -> T {
        return returnQueue.removeFirst() as! T
    }

    public func getCacheEntry(key: String) async throws -> CacheEntry? {
        recordCall("getCacheEntry", arguments: ["key": key])
        return nextReturn()
    }

    public func setCacheEntry(cacheEntry: CacheEntry, tags: [String]) async throws {
        recordCall("setCacheEntry", arguments: ["cacheEntry": cacheEntry, "tags": tags])
    }

    public func removeCacheEntry(key: String) async throws {
        recordCall("removeCacheEntry", arguments: ["key": key])
    }

    public func removeCacheEntriesWithTag(tag: String) async throws {
        recordCall("removeCacheEntriesWithTag", arguments: ["tag": tag])
    }

    public func clearCache() async throws {
        recordCall("clearCache")
    }
}
