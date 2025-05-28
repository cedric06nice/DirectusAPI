//
//  LocalDirectusCacheProtocol.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

@MainActor
public protocol LocalDirectusCacheProtocol: Sendable {
    func getCacheEntry(key: String) async throws -> CacheEntry?
    func setCacheEntry(cacheEntry: CacheEntry, tags: [String]) async throws
    func removeCacheEntry(key: String) async throws
    func removeCacheEntriesWithTag(tag: String) async throws
    func clearCache() async throws
}
