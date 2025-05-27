//
//  DirectusTestHelpers.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
@testable import DirectusAPI
import Foundation

@MainActor
enum DirectusTestHelpers {
    static let defaultAccessToken = "ABCD.1234.ABCD"
    static let defaultRefreshToken = "DEFAULT.REFRESH.TOKEN"

    static func makeAuthenticatedDirectusAPI() async -> DirectusAPI {
        let api = DirectusAPI(baseURL: "http://api.com")
        let response = HTTPURLResponse(
            url: URL(string: "http://api.com/auth/login")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let json = """
        {
            "data": {
                "access_token": "\(defaultAccessToken)",
                "expires": 900000,
                "refresh_token": "\(defaultRefreshToken)"
            }
        }
        """.data(using: .utf8)!

        _ = await api.parseLoginResponse(data: json, response: response)
        return api
    }
}
