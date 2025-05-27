//
//  JsonCacheEngine.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

@MainActor
public final class JsonCacheEngine: LocalDirectusCacheProtocol {
    private let cacheFolderURL: URL
    private var tagsFileContent: TagsFileContent = TagsFileContent.empty

    public init(cacheFolderPath: String) {
        self.cacheFolderURL = URL(fileURLWithPath: cacheFolderPath)
        try? FileManager.default.createDirectory(at: cacheFolderURL, withIntermediateDirectories: true)
    }

    private func filePath(forKey key: String) -> URL {
        let sanitized = key.replacingOccurrences(of: "[^a-zA-Z0-9]", with: ".", options: .regularExpression)
        return cacheFolderURL.appendingPathComponent("\(sanitized).json")
    }

    public func getCacheEntry(key: String) async throws -> CacheEntry? {
        let fileURL = filePath(forKey: key)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(CacheEntry.self, from: data)
    }

    public func setCacheEntry(cacheEntry: CacheEntry, tags: [String]) async throws {
        let fileURL = filePath(forKey: cacheEntry.key)
        let data = try JSONEncoder().encode(cacheEntry)
        try data.write(to: fileURL, options: .atomic)

        if !tags.isEmpty {
            for tag in tags {
                tagsFileContent.addEntry(tag: tag, key: cacheEntry.key)
            }
            try saveTagsFileContent()
        }
    }

    public func removeCacheEntry(key: String) async throws {
        let fileURL = filePath(forKey: key)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    public func removeCacheEntriesWithTag(tag: String) async throws {
        let keys = tagsFileContent.getEntriesWithTag(tag: tag)
        for key in keys {
            try await removeCacheEntry(key: key)
        }
        tagsFileContent.removeAllEntriesWithTag(tag: tag)
        try saveTagsFileContent()
    }

    public func clearCache() async throws {
        let fileURLs = try FileManager.default.contentsOfDirectory(at: cacheFolderURL, includingPropertiesForKeys: nil)
        for url in fileURLs where url.pathExtension == "json" {
            try FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Tag Storage

    private var tagsFileURL: URL {
        return cacheFolderURL.appendingPathComponent("tags.json")
    }

    private func saveTagsFileContent() throws {
        let data = try JSONEncoder().encode(tagsFileContent)
        try data.write(to: tagsFileURL, options: .atomic)
    }

    private func loadTagsFileContentIfNeeded() {
        guard tagsFileContent.isEmpty else { return }
        guard FileManager.default.fileExists(atPath: tagsFileURL.path),
              let data = try? Data(contentsOf: tagsFileURL),
              let loaded = try? JSONDecoder().decode(TagsFileContent.self, from: data) else {
            tagsFileContent = .empty
            return
        }
        tagsFileContent = loaded
    }

    // Ensure tags are loaded before use
    private func ensureTagsLoaded() {
        loadTagsFileContentIfNeeded()
    }
}
