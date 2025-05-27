//
//  DirectusUserManagementTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
@testable import DirectusAPI
import Foundation

@MainActor
struct DirectusUserManagementTests {

    @Test
    func testGetSpecificUserRequest() async {
        let sut = await DirectusTestHelpers.makeAuthenticatedDirectusAPI()
        let request = sut.prepareGetSpecificItemRequest(
            endpointPrefix: "/",
            endpointName: "users",
            itemId: "123"
        ).request as! URLRequest

        #expect(request.url?.absoluteString == "http://api.com/users/123?fields=*")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(DirectusTestHelpers.defaultAccessToken)")
    }

    @Test
    func testGetCurrentUserRequest() async {
        let sut = await DirectusTestHelpers.makeAuthenticatedDirectusAPI()
        let request = sut.prepareGetCurrentUserRequest().request as! URLRequest

        #expect(request.url?.absoluteString == "http://api.com/users/me?fields=*")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(DirectusTestHelpers.defaultAccessToken)")
    }

    @Test
    func testGetCurrentUserRequestWithFields() async {
        let sut = await DirectusTestHelpers.makeAuthenticatedDirectusAPI()
        let request = sut.prepareGetCurrentUserRequest(
            fields: "*,field1.*,field2.*"
        ).request as! URLRequest

        #expect(request.url?.absoluteString == "http://api.com/users/me?fields=*,field1.*,field2.*")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(DirectusTestHelpers.defaultAccessToken)")
    }

    @Test
    func testDeleteUserRequest() async {
        let sut = await DirectusTestHelpers.makeAuthenticatedDirectusAPI()
        let request = sut.prepareDeleteItemRequest(
            endpointPrefix: "/",
            endpointName: "users",
            itemId: "123-abc-456",
            mustBeAuthenticated: true
        ).request as! URLRequest

        #expect(request.url?.absoluteString == "http://api.com/users/123-abc-456")
        #expect(request.httpMethod == "DELETE")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(DirectusTestHelpers.defaultAccessToken)")
    }

    @Test
    func testPrepareUserInviteRequest() {
        let sut = DirectusAPI(baseURL: "http://api.com")
        let request = sut.prepareUserInviteRequest(
            email: "will@acn.com",
            roleId: "abc-user-role-123"
        ).request as! URLRequest

        #expect(request.url?.absoluteString == "http://api.com/users/invite")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type")?.contains("application/json") == true)

        let body = try? JSONSerialization.jsonObject(with: request.httpBody ?? Data(), options: []) as? [String: String]
        #expect(body?["email"] == "will@acn.com")
        #expect(body?["role"] == "abc-user-role-123")
    }
}
