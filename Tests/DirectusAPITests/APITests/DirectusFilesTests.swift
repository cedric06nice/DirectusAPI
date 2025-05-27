//
//  DirectusFilesTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
import XCTest
@testable import DirectusAPI
import Foundation

@MainActor
struct DirectusFilesTests {

    @Test("prepareMultipartFileRequest includes title, folder, and storage fields")
    func testMultipartFileRequestIncludesMetadata() {
        let api = DirectusAPI(baseURL: "http://api.com")
        let request = api._prepareMultipartFileRequest(
            method: "POST",
            url: "http://api.com/files",
            fileBytes: nil,
            title: "Test File",
            contentType: nil,
            filename: "ignored.txt",
            folder: "TestFolder"
        )
        
        let bodyString = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
        #expect(bodyString.contains("name=\"title\""))
        #expect(bodyString.contains("Test File"))
        #expect(bodyString.contains("name=\"folder\""))
        #expect(bodyString.contains("TestFolder"))
        #expect(bodyString.contains("name=\"storage\""))
        #expect(bodyString.contains("local"))
    }

    @Test("prepareMultipartFileRequest includes file and headers correctly")
    func testMultipartFileRequestIncludesFile() {
        let api = DirectusAPI(baseURL: "http://api.com")
        let request = api._prepareMultipartFileRequest(
            method: "POST",
            url: "http://api.com/files",
            fileBytes: [0x48, 0x65, 0x6C, 0x6C, 0x6F], // "Hello"
            title: nil,
            contentType: "text/plain",
            filename: "hello.txt"
        )
        
        let bodyString = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
        #expect(bodyString.contains("Content-Disposition: form-data; name=\"file\"; filename=\"hello.txt\""))
        #expect(bodyString.contains("Content-Type: text/plain"))
        #expect(bodyString.contains("Hello"))
        #expect(request.value(forHTTPHeaderField: "Content-Type")?.contains("multipart/form-data; boundary=") == true)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "http://api.com/files")
    }
    
    @Test("prepareMultipartFileRequest supports PATCH method and omits nils")
    func testMultipartFileRequestPatchMethodOmitsNils() {
        let api = DirectusAPI(baseURL: "http://api.com")
        let request = api._prepareMultipartFileRequest(
            method: "PATCH",
            url: "http://api.com/files/update",
            fileBytes: nil,
            title: nil,
            contentType: nil,
            filename: "unused.txt"
        )
        
        let bodyString = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
        #expect(bodyString.contains("name=\"storage\""))
        #expect(!bodyString.contains("name=\"title\""))
        #expect(!bodyString.contains("name=\"folder\""))
        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.absoluteString == "http://api.com/files/update")
    }
    
    @Test("prepareMultipartFileRequest with empty file bytes still forms valid multipart")
    func testMultipartFileRequestWithEmptyBytes() {
        let api = DirectusAPI(baseURL: "http://api.com")
        let request = api._prepareMultipartFileRequest(
            method: "POST",
            url: "http://api.com/files",
            fileBytes: [],
            title: "Empty File",
            contentType: "application/octet-stream",
            filename: "empty.dat"
        )
        
        let body = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
        #expect(body.contains("name=\"file\"; filename=\"empty.dat\""))
        #expect(body.contains("Content-Type: application/octet-stream"))
        #expect(request.httpMethod == "POST")
    }
    
    @Test("prepareMultipartFileRequest with unusual MIME type")
    func testMultipartFileRequestWithUnusualMimeType() {
        let api = DirectusAPI(baseURL: "http://api.com")
        let request = api._prepareMultipartFileRequest(
            method: "POST",
            url: "http://api.com/files",
            fileBytes: [0x00, 0x01, 0x02],
            title: "Unusual File",
            contentType: "application/x-custom-binary",
            filename: "custom.bin"
        )
        
        let body = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
        #expect(body.contains("Content-Type: application/x-custom-binary"))
        #expect(body.contains("filename=\"custom.bin\""))
    }
    
    @Test("prepareMultipartFileRequest with filename containing spaces and special characters")
    func testMultipartFileRequestWithEscapedFilename() {
        let api = DirectusAPI(baseURL: "http://api.com")
        let filename = "my file @2025!.txt"
        let request = api._prepareMultipartFileRequest(
            method: "POST",
            url: "http://api.com/files",
            fileBytes: [0x41, 0x42, 0x43],
            title: "Escaped File",
            contentType: "text/plain",
            filename: filename
        )
        
        let body = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
        #expect(body.contains("filename=\"\(filename)\""))
        #expect(body.contains("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\""))
    }
    
    @Test("prepareMultipartFileRequest includes boundary and accurate Content-Length")
    func testMultipartFileRequestIncludesBoundaryAndContentLength() {
        let api = DirectusAPI(baseURL: "http://api.com")
        let request = api._prepareMultipartFileRequest(
            method: "POST",
            url: "http://api.com/files",
            fileBytes: [0x41, 0x42, 0x43], // "ABC"
            title: "Boundary Check",
            contentType: "text/plain",
            filename: "boundary.txt"
        )
        
        let headers = request.allHTTPHeaderFields ?? [:]
        
        guard let contentType = headers["Content-Type"] else {
            XCTFail("Content-Type header missing")
            return
        }
        
        #expect(contentType.starts(with: "multipart/form-data; boundary="))
        let boundary = contentType.replacingOccurrences(of: "multipart/form-data; boundary=", with: "")
        
        let body = request.httpBody ?? Data()
        let bodyString = String(data: body, encoding: .utf8) ?? ""
        
        // Check boundary format
        #expect(bodyString.contains("--\(boundary)\r\n"))
        #expect(bodyString.contains("--\(boundary)--"))
        
        // Check content length matches body
        if let contentLengthString = headers["Content-Length"], let declaredLength = Int(contentLengthString) {
            #expect(declaredLength == body.count)
        } else {
            // If no content length explicitly set, make sure body is non-empty
            #expect(!body.isEmpty)
        }
    }
}
