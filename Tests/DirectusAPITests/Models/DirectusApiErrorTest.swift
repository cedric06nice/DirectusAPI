//
//  DirectusApiErrorTest.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
@testable import DirectusAPI

@MainActor
struct DirectusApiErrorTest {
    
    @Test func testErrorDescription_withValidErrorJSON() async throws {
        let json = """
        {
            "errors": [
                { "message": "Invalid token" },
                { "message": "Authentication failed" }
            ]
        }
        """.data(using: .utf8)
        
        let error = DirectusApiError(
            response: nil,
            bodyData: json,
            customMessage: nil
        )
        
        assert(error.errorDescription == "Invalid token, Authentication failed")
    }
    
    @Test func testErrorDescription_withUnexpectedJSON() async throws {
        let json = """
        {
            "error": "Something went wrong"
        }
        """.data(using: .utf8)
        
        let error = DirectusApiError(
            response: nil,
            bodyData: json,
            customMessage: "Default error"
        )
        
        assert(error.errorDescription?.contains("Unexpected JSON format") == true)
    }
    
    @Test func testErrorDescription_withInvalidJSON() async throws {
        let invalidJSON = "{not valid}".data(using: .utf8)
        
        let error = DirectusApiError(
            response: nil,
            bodyData: invalidJSON,
            customMessage: nil
        )
        
        assert(error.errorDescription?.contains("Failed to parse error") == true)
    }
    
    @Test func testErrorDescription_withNoBodyDataAndCustomMessage() async throws {
        let error = DirectusApiError(
            response: nil,
            bodyData: nil,
            customMessage: "Something went wrong"
        )
        
        assert(error.errorDescription == "DirectusApiError: Something went wrong")
    }
    
    @Test func testErrorDescription_withNoBodyDataAndNoCustomMessage() async throws {
        let error = DirectusApiError(
            response: nil,
            bodyData: nil,
            customMessage: nil
        )
        
        assert(error.errorDescription == "DirectusApiError: No custom message")
    }
}
