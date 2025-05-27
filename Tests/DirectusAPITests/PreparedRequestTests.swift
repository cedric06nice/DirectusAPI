//
//  PreparedRequestTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
@testable import DirectusAPI

@MainActor
struct PreparedRequestTests {
    
    struct DummyRequest: Equatable {
        let path: String
    }

    @Test
    func testInitializerStoresRequestAndTags() {
        let dummy = DummyRequest(path: "/test")
        let tags = ["tag1", "tag2"]
        let prepared = PreparedRequest(request: dummy, tags: tags)

        #expect((prepared.request as? DummyRequest)?.path == "/test")
        #expect(prepared.tags == tags)
    }

    @Test
    func testDefaultTagsIsEmptyArray() {
        let dummy = DummyRequest(path: "/default")
        let prepared = PreparedRequest(request: dummy)

        #expect((prepared.request as? DummyRequest)?.path == "/default")
        #expect(prepared.tags.isEmpty)
    }

    @Test
    func testTagListCanBeQueried() {
        let prepared = PreparedRequest(request: "anything", tags: ["alpha", "beta"])
        #expect(prepared.tags.contains("alpha"))
        #expect(prepared.tags.contains("beta"))
    }
}
