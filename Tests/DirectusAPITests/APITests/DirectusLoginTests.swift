//
//  DirectusLoginTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
@testable import DirectusAPI
import Foundation

@MainActor
struct DirectusLoginTests {

    @Test
    func testSuccessfulLoginResponse() async {
        var savedToken: String?
        let sut = DirectusAPI(
            baseURL: "http://api.com",
            saveRefreshToken: { token in savedToken = token }
        )
        let json = """
        {
            "data": {
                "access_token": "ABCD.1234.ABCD",
                "expires": 900000,
                "refresh_token": "REFRESH.TOKEN.5678"
            }
        }
        """.data(using: .utf8)!
        let response = HTTPURLResponse(
            url: URL(string: "http://api.com/auth/login")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let result = await sut.parseLoginResponse(data: json, response: response)

        #expect(result.type == .success)
        #expect(result.message == nil)
        #expect(sut.accessToken == "ABCD.1234.ABCD")
        #expect(sut.refreshToken == "REFRESH.TOKEN.5678")
        #expect(savedToken == "REFRESH.TOKEN.5678")
        #expect(sut.shouldRefreshToken == false)
        #expect(sut.hasLoggedInUser == true)
    }

    @Test
    func testInvalidCredentialsLoginResponse() async {
        let sut = DirectusAPI(baseURL: "http://api.com")
        let json = """
        {
            "errors": [
                {
                    "message": "Invalid user credentials.",
                    "extensions": {
                        "code": "INVALID_CREDENTIALS"
                    }
                }
            ]
        }
        """.data(using: .utf8)!
        let response = HTTPURLResponse(
            url: URL(string: "http://api.com/auth/login")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!

        let result = await sut.parseLoginResponse(data: json, response: response)

        #expect(result.type == .invalidCredentials)
        #expect(result.message == "Invalid user credentials.")
        #expect(sut.accessToken == nil)
        #expect(sut.refreshToken == nil)
    }

    @Test
    func testInvalidOTPLoginResponse() async {
        let sut = DirectusAPI(baseURL: "http://api.com")
        let json = """
        {
            "errors": [
                {
                    "message": "Invalid user OTP.",
                    "extensions": {
                        "code": "INVALID_OTP"
                    }
                }
            ]
        }
        """.data(using: .utf8)!
        let response = HTTPURLResponse(
            url: URL(string: "http://api.com/auth/login")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!

        let result = await sut.parseLoginResponse(data: json, response: response)

        #expect(result.type == .invalidOTP)
        #expect(result.message == "Invalid user OTP.")
        #expect(sut.accessToken == nil)
        #expect(sut.refreshToken == nil)
    }

    @Test
    func testSpecialErrorLoginResponse() async {
        let sut = DirectusAPI(baseURL: "http://api.com")
        let json = """
        {
            "errors": [
                {
                    "message": "Special error",
                    "extensions": {
                        "code": "SPECIAL_ERROR"
                    }
                }
            ]
        }
        """.data(using: .utf8)!
        let response = HTTPURLResponse(
            url: URL(string: "http://api.com/auth/login")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )!

        let result = await sut.parseLoginResponse(data: json, response: response)

        #expect(result.type == .error)
        #expect(result.message == "Special error")
        #expect(sut.accessToken == nil)
        #expect(sut.refreshToken == nil)
    }

    @Test
    func testMalformedLoginResponse() async {
        let sut = DirectusAPI(baseURL: "http://api.com")
        let json = """
        {
            "data": {
                "weird_json": "ABCD.1234.ABCD",
                "fake_key": 900000,
                "tok_tok": "REFRESH.TOKEN.5678"
            }
        }
        """.data(using: .utf8)!
        let response = HTTPURLResponse(
            url: URL(string: "http://api.com/auth/login")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let result = await sut.parseLoginResponse(data: json, response: response)

        #expect(result.type == .error)
        #expect(result.message == "Incomplete token response.")
        #expect(sut.accessToken == nil)
        #expect(sut.refreshToken == nil)
    }
    
    @Test
    func testSuccessfulRefreshTokenLogin() async throws {
        // Arrange
        let mockClient = URLSession(configuration: .ephemeral)
        let sut = DirectusApiManager(
            baseURL: "http://api.com",
            httpClient: mockClient,
            loadRefreshTokenCallback: {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                return "SAVED.TOKEN"
            }
        )
        
        // Act
        let isLoggedIn = try await sut.hasLoggedInUser()
        
        // Assert
        #expect(isLoggedIn == true)
    }
}
