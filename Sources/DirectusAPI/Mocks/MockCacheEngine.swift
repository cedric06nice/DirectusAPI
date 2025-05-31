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

    private func nextReturn<T>() throws -> T {
        guard !returnQueue.isEmpty else {
            throw MockCacheEngineError.emptyReturnQueue(expected: T.self)
        }
        let value = returnQueue.removeFirst()
        guard let casted = value as? T else {
            throw MockCacheEngineError.emptyReturnQueue(expected: T.self)
        }
        return casted
    }

    public func getCacheEntry(key: String) async throws -> CacheEntry? {
        recordCall("getCacheEntry", arguments: ["key": key])
        return try nextReturn()
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

enum MockCacheEngineError: Error, CustomStringConvertible {
    case emptyReturnQueue(expected: Any.Type)
    
    var description: String {
        switch self {
        case .emptyReturnQueue(let expected):
            return "MockCacheEngineError: returnQueue is empty or does not contain type \(expected)"
        }
    }
}
