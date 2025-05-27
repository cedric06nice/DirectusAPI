//
//  TagsFileContent.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

@MainActor
struct TagsFileContent: Codable {
    private(set) var taggedEntries: [String: [String]]

    static var empty: TagsFileContent {
        TagsFileContent(taggedEntries: [:])
    }

    var isEmpty: Bool {
        taggedEntries.isEmpty
    }

    mutating func addEntry(tag: String, key: String) {
        taggedEntries[tag, default: []].append(key)
        taggedEntries[tag] = Array(Set(taggedEntries[tag]!)) // remove duplicates
    }

    func getEntriesWithTag(tag: String) -> [String] {
        return taggedEntries[tag] ?? []
    }

    mutating func removeAllEntriesWithTag(tag: String) {
        taggedEntries.removeValue(forKey: tag)
    }
}
