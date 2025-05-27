//
//  DirectusAccessTokenTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
@testable import DirectusAPI

@MainActor
struct DirectusAccessTokenTests {
    @Test
    func testAccessToken() async {
        let sut = await DirectusTestHelpers.makeAuthenticatedDirectusAPI()
        #expect(sut.accessToken == DirectusTestHelpers.defaultAccessToken)
        #expect(sut.shouldRefreshToken == false)
    }

    @Test
    func testShouldRefreshTokenFromBackup() {
        let sut = DirectusAPI(baseURL: "http://api.com",
                              loadRefreshToken: { "LOADED.TOKEN" })
        #expect(sut.shouldRefreshToken == true)
    }
}
