//
//  DirectusItemTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
@testable import DirectusAPI
import XCTest

@MainActor
struct DirectusItemTests {
    @Test("Initializes DirectusItem with raw dictionary")
    func testInitWithData() throws {
        let item = try DirectusItem(["id": "item-001", "name": "Test"])
        #expect(item.id == "item-001")
        #expect(item.getValue(forKey: "name") as? String == "Test")
    }

    @Test("Creates new DirectusItem with no data")
    func testNewFactory() throws {
        if let item = try? DirectusItem.new() {
            #expect(item.id != nil)  // UUID created inside
        } else {
            throw XCTestError(
                .failureWhileWaiting,
                userInfo: ["ERROR":"TEST FAILED: Could not create new DirectusItem"]
            )
        }
    }

    @Test("Creates DirectusItem from ID")
    func testWithIdFactory() {
        if let item = try? DirectusItem.withId("xyz-123") {
            #expect(item.id == "xyz-123")
        }
    }

    @Test("Set and retrieve custom property")
    func testSetValue() throws {
        if let item = try? DirectusItem.withId("test") {
            item.setValue("foo", forKey: "bar")
            #expect(item.getValue(forKey: "bar") as? String == "foo")
        }
    }
}
