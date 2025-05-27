//
//  DirectusLoginResultTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
@testable import DirectusAPI

@MainActor
struct DirectusLoginResultTests {
    
    @Test
    func testSuccessStaticInstance() {
        let result = DirectusLoginResult.success
        #expect(result.type == .success)
        #expect(result.message == nil)
    }

    @Test
    func testInitWithMessage() {
        let result = DirectusLoginResult(type: .invalidCredentials, message: "Wrong password")
        #expect(result.type == .invalidCredentials)
        #expect(result.message == "Wrong password")
    }

    @Test
    func testInitWithoutMessage() {
        let result = DirectusLoginResult(type: .invalidOTP)
        #expect(result.type == .invalidOTP)
        #expect(result.message == nil)
    }

    @Test
    func testInitWithErrorType() {
        let result = DirectusLoginResult(type: .error, message: "Unknown error")
        #expect(result.type == .error)
        #expect(result.message == "Unknown error")
    }
}
