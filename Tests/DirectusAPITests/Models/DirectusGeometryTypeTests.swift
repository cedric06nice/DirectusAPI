//
//  DirectusGeometryTypeTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
@testable import DirectusAPI
import Foundation

@MainActor 
struct DirectusGeometryTypeTests {
    
    @Test
    func testInit() {
        let geo = DirectusGeometryType(type: "Point", coordinates: [10.0, 20.0])
        #expect(geo.type == "Point")
        #expect(geo.coordinates == [10.0, 20.0])
    }

    @Test
    func testMapPoint() {
        let geo = DirectusGeometryType.mapPoint(latitude: 48.8566, longitude: 2.3522)
        #expect(geo.type == "Point")
        #expect(geo.coordinates == [2.3522, 48.8566])
    }

    @Test
    func testPointXY() {
        let geo = DirectusGeometryType.point(x: 100.0, y: 200.0)
        #expect(geo.type == "Point")
        #expect(geo.coordinates == [100.0, 200.0])
    }

    @Test
    func testCoordinateAccessors() {
        let geo = DirectusGeometryType(type: "Point", coordinates: [5.0, 6.0])
        #expect(geo.pointLongitude == 5.0)
        #expect(geo.pointLatitude == 6.0)
        #expect(geo.pointX == 5.0)
        #expect(geo.pointY == 6.0)
    }

    @Test
    func testCoordinateAccessorsWithEmptyCoordinates() {
        let geo = DirectusGeometryType(type: "Point", coordinates: [])
        #expect(geo.pointLongitude == nil)
        #expect(geo.pointLatitude == nil)
        #expect(geo.pointX == nil)
        #expect(geo.pointY == nil)
    }

    @Test
    func testToJson() {
        let geo = DirectusGeometryType(type: "Point", coordinates: [1.1, 2.2])
        let json = geo.toJSON()
        #expect(json["type"] as? String == "Point")
        #expect(json["coordinates"] as? [Double] == [1.1, 2.2])
    }

    @Test
    func testFromJsonValid() {
        let json: [String: Any] = ["type": "Point", "coordinates": [10.0, 20.0]]
        let geo = DirectusGeometryType.fromJSON(json)
        #expect(geo != nil)
        #expect(geo?.type == "Point")
        #expect(geo?.coordinates == [10.0, 20.0])
    }

    @Test
    func testFromJsonInvalid() {
        let json1: [String: Any] = [:]
        let json2: [String: Any] = ["type": "Point"]
        let json3: [String: Any] = ["coordinates": [1.0, 2.0]]
        let json4: [String: Any] = ["type": 123, "coordinates": [1.0, 2.0]]
        let json5: [String: Any] = ["type": "Point", "coordinates": "not a list"]

        #expect(DirectusGeometryType.fromJSON(json1) == nil)
        #expect(DirectusGeometryType.fromJSON(json2) == nil)
        #expect(DirectusGeometryType.fromJSON(json3) == nil)
        #expect(DirectusGeometryType.fromJSON(json4) == nil)
        #expect(DirectusGeometryType.fromJSON(json5) == nil)
    }

    @Test
    func testEquatableConformance() {
        let a = DirectusGeometryType(type: "Point", coordinates: [1, 2])
        let b = DirectusGeometryType(type: "Point", coordinates: [1, 2])
        let c = DirectusGeometryType(type: "Point", coordinates: [2, 1])
        #expect(a == b)
        #expect(a != c)
    }

    @Test
    func testCodableRoundTrip() throws {
        let original = DirectusGeometryType(type: "Point", coordinates: [4.0, 5.0])
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DirectusGeometryType.self, from: encoded)
        #expect(decoded == original)
    }

    @Test
    func testInvalidCodableDecoding() {
        let badJSON = """
        {
          "type": 123,
          "coordinates": "oops"
        }
        """.data(using: .utf8)!

        do {
            _ = try JSONDecoder().decode(DirectusGeometryType.self, from: badJSON)
            #expect(Bool(false), "Decoding should have failed for malformed JSON")
        } catch {
            #expect(Bool(true)) // pass
        }
    }
}
