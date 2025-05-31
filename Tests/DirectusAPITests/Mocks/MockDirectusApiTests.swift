//
//  MockDirectusApiTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 31/05/2025.
//

import Testing
import Foundation
@testable import DirectusAPI

@MainActor
@Suite
struct MockDirectusApiTests {

    @Test
    func testParseCreateNewItemResponseReturnsValue() throws {
        let mock = MockDirectusApi()
        mock.nextParsedResponse = ["id": "123"]
        let data = Data()
        let response = HTTPURLResponse()
        let result = try mock.parseCreateNewItemResponse(data: data, response: response)
        #expect((result as? [String: String])?["id"] == "123")
    }

    @Test
    func testParseCreateNewItemResponseThrowsIfMissingValue() {
        let mock = MockDirectusApi()
        let data = Data()
        let response = HTTPURLResponse()
        #expect(
            throws: Error.self) { try mock.parseCreateNewItemResponse(
                data: data,
                response: response
            )
            }
    }

    @Test
    func testParseLoginResponseSetsTokensAndReturnsSuccess() async {
        let mock = MockDirectusApi()
        let result = await mock.parseLoginResponse(data: Data(), response: HTTPURLResponse())
        #expect(result.type == .success)
        #expect(mock.accessToken == "token")
        #expect(mock.refreshToken == "refresh")
    }

    @Test
    func testConvertPathToFullURL() {
        let mock = MockDirectusApi()
        let url = mock.convertPathToFullURL(path: "assets/file.jpg")
        #expect(url == "https://example.com/assets/file.jpg")
    }

    @Test
    func testPrepareRequestReturnsURL() {
        let mock = MockDirectusApi()
        let prepared = mock.prepareGetCurrentUserRequest(fields: "*")
        #expect((prepared.request as? URLRequest)?.url?.absoluteString == "https://example.com")
    }

    @Test
    func testParseFileUploadResponseReturnsMockFile() throws {
        let mock = MockDirectusApi()
        let file = try mock.parseFileUploadResponse(data: Data(), response: HTTPURLResponse())
        #expect(file.id == "mock")
    }
    
    @Test
    func testPrepareLogoutRequestReturnsURL() throws {
        let mock = MockDirectusApi()
        let prepared = try mock.prepareLogoutRequest()
        #expect((prepared?.request as? URLRequest)?.url?.absoluteString == "https://example.com")
    }
    
    @Test
    func testParseLogoutResponseReturnsTrue() throws {
        let mock = MockDirectusApi()
        let result = try mock.parseLogoutResponse(data: Data(), response: HTTPURLResponse())
        #expect(result == true)
    }
    
    @Test
    func testPrepareUserInviteRequestReturnsURL() throws {
        let mock = MockDirectusApi()
        let prepared = try mock.prepareUserInviteRequest(email: "test@example.com", roleId: "admin")
        #expect((prepared.request as? URLRequest)?.url?.absoluteString == "https://example.com")
    }
    
    @Test
    func testParseUserInviteResponseReturnsTrue() throws {
        let mock = MockDirectusApi()
        let result = try mock.parseUserInviteResponse(data: Data(), response: HTTPURLResponse())
        #expect(result == true)
    }
    
    @Test
    func testPrepareFileDeleteRequestReturnsURL() throws {
        let mock = MockDirectusApi()
        let prepared = try mock.prepareFileDeleteRequest(fileId: "file123")
        #expect((prepared.request as? URLRequest)?.url?.absoluteString == "https://example.com")
    }
    
    @Test
    func testPrepareFileDownloadRequestReturnsURL() throws {
        let mock = MockDirectusApi()
        let prepared = try mock.prepareFileDownloadRequest(fileId: "file456")
        #expect((prepared.request as? URLRequest)?.url?.absoluteString == "https://example.com")
    }
    
    @Test
    func testParseFileDownloadResponseReturnsEmptyData() throws {
        let mock = MockDirectusApi()
        let result = try mock.parseFileDownloadResponse(data: Data(), response: HTTPURLResponse())
        #expect(result == Data())
    }
    
    @Test
    func testPrepareNewFileUploadRequestReturnsURL() throws {
        let mock = MockDirectusApi()
        let fileBytes: [UInt8] = [0x89, 0x50, 0x4E, 0x47]
        let prepared = try mock.prepareNewFileUploadRequest(
            fileBytes: fileBytes,
            title: "Test File",
            contentType: "image/png",
            filename: "file.png",
            folder: "images",
            storage: "local"
        )
        #expect((prepared.request as? URLRequest)?.url?.absoluteString == "https://example.com")
    }
    
    @Test
    func testPrepareUpdateFileRequestReturnsURL() throws {
        let mock = MockDirectusApi()
        let fileBytes: [UInt8] = [4, 5, 6]
        let prepared = try mock.prepareUpdateFileRequest(
            fileId: "mock-id",
            fileBytes: fileBytes,
            title: "Updated File",
            contentType: "image/jpeg",
            filename: "updated.jpg"
        )
        #expect((prepared.request as? URLRequest)?.url?.absoluteString == "https://example.com")
    }
    
    @Test
    func testPrepareNewFileUploadRequestWithBytesAndMetadata() throws {
        let mock = MockDirectusApi()
        let fileBytes: [UInt8] = Array("Hello, world!".utf8)
        let prepared = try mock.prepareNewFileUploadRequest(
            fileBytes: fileBytes,
            title: "Greeting",
            contentType: "text/plain",
            filename: "hello.txt",
            folder: nil,
            storage: "memory"
        )
        #expect((prepared.request as? URLRequest)?.url?.absoluteString == "https://example.com")
    }
    
    @Test
    func testPrepareNewFileUploadRequestThrowsWithEmptyFilename() {
        let mock = MockDirectusApi()
        let fileBytes: [UInt8] = [1, 2, 3]
        #expect(throws: Error.self) {
            _ = try mock.prepareNewFileUploadRequest(
                fileBytes: fileBytes,
                title: "Missing filename",
                contentType: "application/octet-stream",
                filename: "",
                folder: nil,
                storage: "disk"
            )
        }
    }
    
    @Test
    func testPrepareUpdateFileRequestThrowsWithMissingId() {
        let mock = MockDirectusApi()
        let fileBytes: [UInt8] = [0]
        #expect(throws: Error.self) {
            _ = try mock.prepareUpdateFileRequest(
                fileId: "",
                fileBytes: fileBytes,
                title: "Update with no ID",
                contentType: "application/json",
                filename: "data.json"
            )
        }
    }
    
    @Test
    func testPrepareNewFileUploadRequestWithMalformedMimeType() {
        let mock = MockDirectusApi()
        let fileBytes: [UInt8] = [0xFF, 0xD8, 0xFF] // JPEG signature start
        #expect(throws: Error.self) {
            _ = try mock.prepareNewFileUploadRequest(
                fileBytes: fileBytes,
                title: "Corrupt",
                contentType: "invalidtype",
                filename: "corrupt.jpg",
                folder: nil,
                storage: "local"
            )
        }
    }
    
    @Test
    func testPrepareNewFileUploadRequestWithUnsupportedExtension() {
        let mock = MockDirectusApi()
        let fileBytes: [UInt8] = [0x25, 0x50, 0x44, 0x46] // PDF header
        #expect(throws: Error.self) {
            _ = try mock.prepareNewFileUploadRequest(
                fileBytes: fileBytes,
                title: "Script",
                contentType: "application/pdf",
                filename: "script.exe", // intentionally misleading
                folder: nil,
                storage: "secure"
            )
        }
    }
    
    @Test
    func testPrepareNewFileUploadRequestWithOversizedFile() {
        let mock = MockDirectusApi()
        let fileBytes = [UInt8](repeating: 0x00, count: 10_000_000) // ~10 MB file
        #expect(throws: Error.self) {
            _ = try mock.prepareNewFileUploadRequest(
                fileBytes: fileBytes,
                title: "Too Big",
                contentType: "application/octet-stream",
                filename: "large.bin",
                folder: nil,
                storage: "local"
            )
        }
    }
    
    @Test
    func testPrepareNewFileUploadRequestWithMismatchedMime() {
        let mock = MockDirectusApi()
        let fileBytes: [UInt8] = Array("<svg><circle /></svg>".utf8) // SVG/XML data
        #expect(throws: Error.self) {
            _ = try mock.prepareNewFileUploadRequest(
                fileBytes: fileBytes,
                title: "Mismatch",
                contentType: "image/jpeg", // incorrect on purpose
                filename: "vector.jpg",
                folder: nil,
                storage: "cdn"
            )
        }
    }
}
