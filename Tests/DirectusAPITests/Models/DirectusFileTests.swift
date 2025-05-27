//
//  DirectusFileTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
@testable import DirectusAPI
import Foundation

@MainActor 
struct DirectusFileTests {
    
    @Test
    func testRatioCalculation() throws {
        let file = try DirectusFile([
            "id": "abc123",
            "width": 1920,
            "height": 1080
        ])
        #expect(file.ratio == 1920.0 / 1080.0)
    }

    @Test
    func testRatioFallback() throws {
        let file = try DirectusFile([
            "id": "abc123",
            "width": 100,
            "height": 0
        ])
        #expect(file.ratio == 1.0)
    }

    @Test
    func testDownloadURLGeneration() throws {
        DirectusFile.baseUrl = "https://example.com"
        let file = try DirectusFile([
            "id": "fileId123"
        ])
        let url = file.getDownloadURL(width: 100, height: 200, quality: 80, otherKeys: ["fit": "cover"])

        #expect(url.contains("width=100"))
        #expect(url.contains("height=200"))
        #expect(url.contains("quality=80"))
        #expect(url.contains("fit=cover"))
        #expect(url.starts(with: "https://example.com/assets/fileId123?"))
    }

    @Test
    func testEquatableConformance() throws {
        let file1 = try DirectusFile(["id": "abc123", "title": "Image A"])
        let file2 = try DirectusFile(["id": "abc123", "title": "Image A"])
        let file3 = try DirectusFile(["id": "def456", "title": "Image B"])

        #expect(file1 == file2)
        #expect(file1 != file3)
    }

    @Test
    func testHashableConformance() throws {
        let file1 = try DirectusFile(["id": "abc123", "title": "Image A"])
        let file2 = try DirectusFile(["id": "abc123", "title": "Image A"])
        let set: Set<DirectusFile> = [file1, file2]
        #expect(set.count == 1)
    }

    @Test
    func testCodableRoundTrip() throws {
        let input = try DirectusFile([
            "id": "abc123",
            "title": "Test File",
            "type": "image/png",
            "uploaded_on": "2025-05-13T12:00:00Z",
            "filesize": 12345,
            "width": 800,
            "height": 600,
            "duration": 30,
            "description": "Test",
            "metadata": ["foo": "bar"]
        ])

        let encoded = try JSONEncoder().encode(input)
        let decoded = try JSONDecoder().decode(DirectusFile.self, from: encoded)

        #expect(decoded.id == "abc123")
        #expect(decoded.title == "Test File")
        #expect(decoded.width == 800)
        #expect(decoded.height == 600)
        #expect(decoded.descriptionText == "Test")
    }
}
