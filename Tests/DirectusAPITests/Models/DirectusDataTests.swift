//
//  DirectusDataTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
import Foundation
@testable import DirectusAPI

@MainActor 
struct DirectusDataTests {
    @Test("initializes successfully with ID")
    func testValidInit() throws {
        let data = try DirectusData(["id": "abc-123"])
        #expect(data.id == "abc-123")
    }
    
    @Test("throws when ID is missing")
    func testInvalidInitThrows() throws {
        #expect(throws: Error.self, performing: {
            try DirectusData([:])
        })
    }
    
    @Test("set and get value")
    func testSetGetValue() throws {
        let data = try DirectusData(["id": "1"])
        data.setValue("Hello", forKey: "greeting")
        #expect(data.getValue(forKey: "greeting") as? String == "Hello")
    }
    
    @Test("detects if value has changed")
    func testChangeDetection() throws {
        let data = try DirectusData(["id": "1", "name": "A"])
        #expect(!data.needsSaving)
        data.setValue("B", forKey: "name")
        #expect(data.needsSaving)
        #expect(data.hasChangedIn(forKey: "name"))
    }
    
    @Test("toMap merges changes")
    func testToMap() throws {
        let data = try DirectusData(["id": "1"])
        data.setValue("world", forKey: "target")
        let map = data.toMap()
        #expect(map["target"] as? String == "world")
    }
    
    @Test("mapForObjectCreation omits ID")
    func testMapForObjectCreation() throws {
        let data = try DirectusData(["id": "xyz", "foo": "bar"])
        let map = data.mapForObjectCreation()
        #expect(map["id"] == nil)
        #expect(map["foo"] as? String == "bar")
    }
    
    @Test("getList extracts typed array")
    func testGetList() throws {
        let data = try DirectusData(["id": "1", "tags": ["a", "b", "c"]])
        let tags: [String] = data.getList(forKey: "tags")
        #expect(tags == ["a", "b", "c"])
    }
    
    @Test("getOptionalDateTime parses ISO8601 string")
    func testDateParsing() throws {
        let now = ISO8601DateFormatter().string(from: .now)
        let data = try DirectusData(["id": "1", "timestamp": now])
        let parsed = data.getOptionalDateTime(forKey: "timestamp")
        #expect(parsed != nil)
    }
    
    @Test("getOptionalGeometryType returns object when valid")
    func testGeometryParsing() throws {
        let mock: [String: Any] = ["type": "Point", "coordinates": [1.0, 2.0]]
        let data = try DirectusData(["id": "1", "location": mock])
        #expect(data.getOptionalDirectusGeometryType(forKey: "location") != nil)
    }
}
