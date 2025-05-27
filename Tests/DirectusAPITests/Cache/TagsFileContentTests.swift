//
//  TagsFileContentTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
@testable import DirectusAPI

@MainActor
struct TagsFileContentTests {
    
    @Test
    func testEmptyStaticProperty() {
        let empty = TagsFileContent.empty
        #expect(empty.isEmpty)
        #expect(empty.getEntriesWithTag(tag: "nonexistent").isEmpty)
    }

    @Test
    func testAddEntryCreatesNewTag() {
        var tags = TagsFileContent.empty
        tags.addEntry(tag: "alpha", key: "key1")
        #expect(tags.getEntriesWithTag(tag: "alpha") == ["key1"])
    }

    @Test
    func testAddEntryAppendsToExistingTag() {
        var tags = TagsFileContent.empty
        tags.addEntry(tag: "alpha", key: "key1")
        tags.addEntry(tag: "alpha", key: "key2")
        let entries = tags.getEntriesWithTag(tag: "alpha")
        #expect(entries.contains("key1"))
        #expect(entries.contains("key2"))
        #expect(entries.count == 2)
    }

    @Test
    func testAddEntryPreventsDuplicates() {
        var tags = TagsFileContent.empty
        tags.addEntry(tag: "alpha", key: "key1")
        tags.addEntry(tag: "alpha", key: "key1")
        let entries = tags.getEntriesWithTag(tag: "alpha")
        #expect(entries == ["key1"])
    }

    @Test
    func testRemoveAllEntriesWithTag() {
        var tags = TagsFileContent.empty
        tags.addEntry(tag: "alpha", key: "key1")
        tags.removeAllEntriesWithTag(tag: "alpha")
        #expect(tags.getEntriesWithTag(tag: "alpha").isEmpty)
    }

    @Test
    func testIsEmptyAfterRemovingAllTags() {
        var tags = TagsFileContent.empty
        tags.addEntry(tag: "alpha", key: "key1")
        tags.removeAllEntriesWithTag(tag: "alpha")
        #expect(tags.isEmpty)
    }

    @Test
    func testIsEmptyWhenInitialized() {
        let tags = TagsFileContent(taggedEntries: [:])
        #expect(tags.isEmpty)
    }

    @Test
    func testGetEntriesWithNonexistentTagReturnsEmpty() {
        let tags = TagsFileContent(taggedEntries: [:])
        #expect(tags.getEntriesWithTag(tag: "ghost").isEmpty)
    }
}
