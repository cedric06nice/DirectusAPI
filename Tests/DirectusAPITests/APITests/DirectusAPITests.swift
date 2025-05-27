//
//  DirectusAPITests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
@testable import DirectusAPI
import Foundation
import XCTest

struct DirectusAPITests {
    
    static let defaultAccessToken = "ABCD.1234.ABCD"
    static let defaultRefreshToken = "DEFAULT.REFRESH.TOKEN"
    
    @MainActor
    private static func makeAuthentificatedDirectusAPI() async -> DirectusAPI {
        let api = DirectusAPI(baseURL: "https://example.com")
        let jsonData = """
                {
                    "data": {
                        "access_token": "\(defaultAccessToken)",
                        "refresh_token": "\(defaultRefreshToken)",
                        "expires": 900000
                    }
                }
            """.data(using: .utf8)!
        
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com/auth/login")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        _ = await api
            .parseLoginResponse(data: jsonData, response: response)
        return api
    }
    
    @MainActor
    struct InitializersTests {
        
        //MARK: init(baseURL:saveRefreshToken:loadRefreshToken:)
        //MARK: currentAuthToken
        //MARK: refreshToken
        @Test("Initialise with baseURL and no token handlers")
        func testInitBare() {
            let sut = DirectusAPI(baseURL: "https://example.com")
            #expect(sut.baseURL == "https://example.com")
            #expect(sut.accessToken == nil)
            #expect(sut.currentAuthToken == nil)
            #expect(sut.refreshToken == nil)
            #expect(sut.shouldRefreshToken == false)
        }
        
        //MARK: accessToken
        @Test("Get access token")
        func testAccessToken() async throws {
            let api = await makeAuthentificatedDirectusAPI()
            #expect(api.accessToken == defaultAccessToken)
            #expect(api.shouldRefreshToken == false)
        }
        
        @Test("Initialise with baseURL and token handlers")
        func testInitWithTokenHandlers() async {
            var savedToken: String?
            var loaderCalled = false
            
            let api = DirectusAPI(
                baseURL: "https://example.com",
                saveRefreshToken: { token in
                    savedToken = token
                },
                loadRefreshToken: {
                    loaderCalled = true
                    return "loadedToken"
                }
            )
            
            #expect(api.baseURL == "https://example.com")
            #expect(api.accessToken == nil)
            #expect(api.refreshToken == nil)
            
            // Simulate saving a token
            await api._saveRefreshToken?("savedToken")
            #expect(savedToken == "savedToken")
            
            // Simulate loading a token
            let loaded = await api._loadRefreshToken?()
            #expect(loaderCalled)
            #expect(loaded == "loadedToken")
        }
        
        //MARK: baseURL
        @Test("No trailing slash")
        func testBaseURL() {
            let api = DirectusAPI(baseURL: "https://example.com")
            #expect(api.baseURL == "https://example.com")
        }
        
        @Test("Trim trailing slash")
        func testBaseURLTrimsSlash() {
            let api = DirectusAPI(baseURL: "https://example.com/")
            #expect(api.baseURL == "https://example.com")
        }
        
        //MARK: shouldRefreshToken
        @Test("Should refrest token when no refreshToken")
        func testShouldRefreshTokenWhenNoRefreshToken() {
            let api = DirectusAPI(baseURL: "https://example.com")
            api._accessToken = "token"
            api._refreshToken = nil
            #expect(api.shouldRefreshToken == false)
        }
        
        @Test("ShouldRefreshToken - when loadable from backup")
        func testShouldRefreshTokenWhenLoadableFromBackup() {
            let sut = DirectusAPI(
                baseURL: "https://example.com",
                loadRefreshToken: { "LOADED.TOKEN" })
            #expect(sut.shouldRefreshToken == true)
        }
        
        @Test("Should not refresh token when not expired")
        func testShouldRefreshTokenWhenNotExpired() {
            let api = DirectusAPI(baseURL: "https://example.com")
            api._accessToken = "token"
            api._refreshToken = "refreshToken"
            api._accessTokenExpiration = Date().addingTimeInterval(3600)
            #expect(api.shouldRefreshToken == false)
        }
        
        @Test("Should not refresh token if no expiration date set")
        func testShouldRefreshTokenWhenNoExpirationDateSet() {
            let api = DirectusAPI(baseURL: "https://example.com")
            api._accessToken = "token"
            api._refreshToken = "refreshToken"
            api._accessTokenExpiration = nil
            #expect(api.shouldRefreshToken == false)
        }
        
        @Test("Should refresh token when expired")
        func testShouldRefreshTokenWhenExpired() {
            let api = DirectusAPI(baseURL: "https://example.com")
            api._accessToken = "token"
            api._refreshToken = "refreshToken"
            api._accessTokenExpiration = Date().addingTimeInterval(-1)
            #expect(api.shouldRefreshToken == true)
        }
    }
    
    @MainActor
    struct Path {
        
        //MARK: convertPathToFullURL(path:)
        @Test("Convert path to full URL")
        func testConvertPathToFullURL() {
            let api = DirectusAPI(baseURL: "https://api.example.com")
            #expect(api.convertPathToFullURL(path: "/assets") == "https://api.example.com/assets")
        }
        
        @Test("Convert path to full URL with 2 components")
        func testConvertPathToFullURLwithTwoComponents() {
            let api = DirectusAPI(baseURL: "https://api.example.com")
            #expect(api.convertPathToFullURL(path: "/items/test") == "https://api.example.com/items/test")
        }
    }
    
    @MainActor
    struct LoggedInUserTests {
        
        //MARK: hasLoggedInUser()
        @Test("Logged in user should be false when token and refresh token are not present")
        func testHasLoggedInUserFalse() async {
            let api = DirectusAPI(baseURL: "https://example.com")
            #expect(api.hasLoggedInUser == false)
        }
        
        @Test("Logged in user should be true when token and refresh token are present")
        func testHasLoggedInUserTrue() async {
            let api = DirectusAPI(baseURL: "https://example.com")
            api._accessToken = "abc"
            api._refreshToken = "def"
            #expect(api.hasLoggedInUser == true)
        }
    }
    
    @MainActor
    struct AuthenticationsTests {
        
        //MARK: authenticateRequest(_:)
        @Test("Authenticate request adds Authorization header")
        func testAuthenticateRequestAddsHeader() {
            let api = DirectusAPI(baseURL: "https://example.com")
            api._accessToken = "token"
            var request = URLRequest(url: URL(string: "https://example.com")!)
            let authenticated = api.authenticateRequest(&request)
            #expect(authenticated.value(forHTTPHeaderField: "Authorization") == "Bearer token")
        }
    }
    
    @MainActor
    struct LoginTests {
        
        //MARK: prepareLoginRequest(username:password:oneTimePassword:)
        @Test("Prepare login without otp")
        func testPrepareLoginRequest() throws {
            let api = DirectusAPI(baseURL: "https://example.com")
            let prepared: PreparedRequest = try api.prepareLoginRequest(username: "user@example.com", password: "pass")
            let request = prepared.request as! URLRequest
            let body = try XCTUnwrap(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            #expect(request.httpMethod == "POST")
            #expect(request.url?.absoluteString == "https://example.com/auth/login")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(json?.keys.count == 2)
            #expect(json?["email"] as? String == "user@example.com")
            #expect(json?["password"] as? String == "pass")
        }
        
        @Test("Prepare login includes otp")
        func testPrepareLoginRequestIncludesOtp() throws {
            let api = DirectusAPI(baseURL: "https://example.com")
            let prepared: PreparedRequest = try api.prepareLoginRequest(username: "user@example.com", password: "pass", oneTimePassword: "123456")
            let request = prepared.request as! URLRequest
            let body = try XCTUnwrap(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            #expect(request.httpMethod == "POST")
            #expect(request.url?.absoluteString == "https://example.com/auth/login")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(json?.keys.count == 3)
            #expect(json?["email"] as? String == "user@example.com")
            #expect(json?["password"] as? String == "pass")
            #expect(json?["otp"] as? String == "123456")
        }
        
        //MARK: parseLoginResponse(data:response:)
        @Test("Parse login response includes token and expiration")
        func parseLoginResponseOk() async throws {
            let jsonData = """
                {
                    "data": {
                        "expires": 900000,
                        "refresh_token": "refresh",
                        "access_token": "token"
                    }
                }
            """.data(using: .utf8)!
            
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/auth/login")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let api = DirectusAPI(baseURL: "https://example.com")
            let result = await api.parseLoginResponse(data: jsonData, response: response)
            #expect(result.type == .success)
            #expect(result.message == nil)
            #expect(api._accessToken == "token")
            #expect(api._refreshToken == "refresh")
        }
        
        @Test("Parse login 401 with invalid credentials")
        func parseLoginResponseInvalidCredentials() async throws {
            let jsonData = """
                {
                    "errors": [
                        {
                            "message": "Invalid credentials",
                            "extensions": {
                                "code": "INVALID_CREDENTIALS"
                            }
                        }
                    ]
                }
                """.data(using: .utf8)!
            
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/auth/login")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let api = DirectusAPI(baseURL: "https://example.com")
            let result = await api.parseLoginResponse(data: jsonData, response: response)
            
            #expect(result.type == .invalidCredentials)
            #expect(result.message == "Invalid credentials")
        }
        
        @Test("Parse login 401 with invalid OTP")
        func parseLoginResponseInvalidOTP() async throws {
            let jsonData = """
                {
                    "errors": [
                        {
                            "message": "OTP is incorrect",
                            "extensions": {
                                "code": "INVALID_OTP"
                            }
                        }
                    ]
                }
                """.data(using: .utf8)!
            
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/auth/login")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let api = DirectusAPI(baseURL: "https://example.com")
            let result = await api.parseLoginResponse(data: jsonData, response: response)
            
            #expect(result.type == .invalidOTP)
            #expect(result.message == "OTP is incorrect")
        }
        
        @Test("Parse login 401 with unknown error code")
        func parseLoginResponseUnknownError() async throws {
            let jsonData = """
                {
                    "errors": [
                        {
                            "message": "Something else",
                            "extensions": {
                                "code": "UNKNOWN_ERROR"
                            }
                        }
                    ]
                }
                """.data(using: .utf8)!
            
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/auth/login")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let api = DirectusAPI(baseURL: "https://example.com")
            let result = await api.parseLoginResponse(data: jsonData, response: response)
            
            #expect(result.type == .error)
            #expect(result.message == "Something else")
        }
        
        @Test("Parse login with error other than 401")
        func parseLoginResponse500() async throws {
            let jsonData = """
                {
                    "errors": [
                        {
                            "message": "Another error",
                            "extensions": {
                                "code": "ERROR"
                            }
                        }
                    ]
                }
                """.data(using: .utf8)!
            
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/auth/login")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let api = DirectusAPI(baseURL: "https://example.com")
            let result = await api.parseLoginResponse(data: jsonData, response: response)
            
            #expect(result.type == .error)
            #expect(result.message == "Another error")
        }
    }
    
    @MainActor
    struct LogoutTests {
        
        //MARK: prepareLogoutRequest()
        @Test("Prepare logout request")
        func testPrepareLogoutRequest() async throws {
            let api = DirectusAPI(baseURL: "https://example.com")
            let prepared = try api.prepareLogoutRequest()
            guard let request = prepared?.request as? URLRequest else {
                XCTFail("prepared.request is not a URLRequest")
                return
            }
            #expect(request.url?.absoluteString == "https://example.com/auth/logout")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(request.httpBody == nil)
        }
        
        //MARK: parseLogoutResponse(data:response:)
        @Test("Parse logout response clears state")
        func testParseLogoutResponseClearsState() throws {
            let api = DirectusAPI(baseURL: "https://example.com")
            api._accessToken = "abc"
            api._refreshToken = "def"
            api._accessTokenExpiration = Date()
            
            let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                           statusCode: 204,
                                           httpVersion: nil,
                                           headerFields: nil)!
            let result = try api.parseLogoutResponse(data: Data(), response: response)
            #expect(result)
            #expect(api._accessToken == nil)
            #expect(api._refreshToken == nil)
            #expect(api._accessTokenExpiration == nil)
        }
        
        @Test("Parse logout response fails with 401 and does not clear state")
        func testParseLogoutResponseUnauthorized() throws {
            let api = DirectusAPI(baseURL: "https://example.com")
            api._accessToken = "abc"
            api._refreshToken = "def"
            api._accessTokenExpiration = Date()
            
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/auth/logout")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let result = try api.parseLogoutResponse(data: Data(), response: response)
            #expect(!result)
            #expect(api._accessToken == "abc")
            #expect(api._refreshToken == "def")
            #expect(api._accessTokenExpiration != nil)
        }
    }
    
    @MainActor
    struct TokenTests {
        
        //MARK: prepareRefreshTokenRequest()
        @Test("Prepare refresh token request does not call loader when _refreshToken is already set")
        func testPrepareRefreshTokenRequestSkipsLoadFunction() async throws {
            var wasCalled = false
            let api = DirectusAPI(
                baseURL: "https://example.com",
                loadRefreshToken: {
                    wasCalled = true
                    return "shouldNotBeUsed"
                }
            )
            
            api._refreshToken = "existingToken"
            
            let prepared = try await api.prepareRefreshTokenRequest()
            
            guard let request = prepared.request as? URLRequest else {
                XCTFail("prepared.request is not a URLRequest")
                return
            }
            
            let body = try XCTUnwrap(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
            
            #expect(request.url?.absoluteString == "https://example.com/auth/refresh")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(!wasCalled)
            #expect(api._refreshToken == "existingToken")
            #expect(json?["refresh_token"] == "existingToken")
        }
        
        @Test("Prepare refresh token request loads token from closure when _refreshToken is nil")
        func testPrepareRefreshTokenRequestWithLoadFunction() async throws {
            var wasCalled = false
            let api = DirectusAPI(
                baseURL: "https://example.com",
                loadRefreshToken: {
                    wasCalled = true
                    return "dynamicRefreshToken"
                }
            )
            
            // Simulate no preloaded refresh token
            api._refreshToken = nil
            
            let prepared = try await api.prepareRefreshTokenRequest()
            
            guard let request = prepared.request as? URLRequest else {
                XCTFail("prepared.request is not a URLRequest")
                return
            }
            
            let body = try XCTUnwrap(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
            
            // Assertions
            #expect(wasCalled)
            #expect(api._refreshToken == "dynamicRefreshToken")
            #expect(request.url?.absoluteString == "https://example.com/auth/refresh")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(json?["refresh_token"] == "dynamicRefreshToken")
        }
        
        @Test("Prepare refresh token request throws error when no token is available")
        func testPrepareRefreshTokenRequestFailsWithoutToken() async {
            let api = DirectusAPI(baseURL: "https://example.com")
            // No loadRefreshToken closure provided
            api._refreshToken = nil // No token set
            
            do {
                _ = try await api.prepareRefreshTokenRequest()
                XCTFail("Expected error to be thrown due to missing refresh token")
            } catch let error as URLError {
                #expect(error.code == .userAuthenticationRequired)
                #expect(error.localizedDescription.contains("Missing refresh token"))
            } catch {
                XCTFail("Unexpected error type: \(error)")
            }
        }
        
        //MARK: parseRefreshTokenResponse(data:response:)
        @Test("Parse refresh token response")
        func testParseRefreshTokenResponse() async throws {
            let jsonData: Data = """
                {
                    "data": {
                        "expires": 900000,
                        "refresh_token": "refresh",
                        "access_token": "token"
                    }
                }
                """.data(using: .utf8)!
            
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/auth/refresh")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let api = DirectusAPI(baseURL: "https://example.com")
            let result = try await api.parseRefreshTokenResponse(data: jsonData, response: response)
            
            #expect(result)
            #expect(api._accessToken == "token")
            #expect(api._refreshToken == "refresh")
            #expect(api._accessTokenExpiration != nil)
        }
    }
    
    @MainActor
    struct UsersManagementTests {
        
        // MARK: prepareRegisterUserRequest(email:password:firstname:lastname:)
        @Test("Prepare register user request with all fields")
        func testPrepareRegisterUserRequestWithAllFields() throws {
            let api = DirectusAPI(baseURL: "https://example.com")
            let prepared = try api.prepareRegisterUserRequest(email: "user@example.com", password: "pass123", firstname: "John", lastname: "Doe")
            
            guard let request = prepared.request as? URLRequest,
                  let body = request.httpBody,
                  let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
            else {
                XCTFail("Invalid URLRequest or body")
                return
            }
            
            #expect(request.httpMethod == "POST")
            #expect(request.url?.absoluteString == "https://example.com/users/register")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(json["email"] == "user@example.com")
            #expect(json["password"] == "pass123")
            #expect(json["first_name"] == "John")
            #expect(json["last_name"] == "Doe")
        }
        
        @Test("Prepare register user request without firstname and lastname")
        func testPrepareRegisterUserRequestMinimal() throws {
            let api = DirectusAPI(baseURL: "https://example.com")
            let prepared = try api.prepareRegisterUserRequest(email: "user@example.com", password: "pass123", firstname: nil, lastname: nil)
            
            guard let request = prepared.request as? URLRequest,
                  let body = request.httpBody,
                  let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
            else {
                XCTFail("Invalid URLRequest or body")
                return
            }
            
            #expect(request.httpMethod == "POST")
            #expect(request.url?.absoluteString == "https://example.com/users/register")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(json["email"] == "user@example.com")
            #expect(json["password"] == "pass123")
            #expect(json["first_name"] == nil)
            #expect(json["last_name"] == nil)
        }
        
        //MARK: prepareUserInviteRequest(email:roleId:)
        @Test("Prepare user invite request with valid parameters")
        func testPrepareUserInviteRequest() throws {
            let api = DirectusAPI(baseURL: "https://example.com")
            let prepared = api.prepareUserInviteRequest(email: "invitee@example.com", roleId: "admin")
            
            guard let request = prepared.request as? URLRequest,
                  let body = request.httpBody,
                  let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
            else {
                XCTFail("Invalid request")
                return
            }
            
            #expect(request.url?.absoluteString == "https://example.com/users/invite")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(json["email"] == "invitee@example.com")
            #expect(json["role"] == "admin")
        }
        
        @Test("Prepare user invite request with invalid email format should pass")
        func testPrepareUserInviteRequestInvalidEmailShouldPass() throws {
            let api = DirectusAPI(baseURL: "https://example.com")
            let prepared = api.prepareUserInviteRequest(email: "bademail", roleId: "user")
            
            guard let request = prepared.request as? URLRequest,
                  let body = request.httpBody,
                  let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
            else {
                XCTFail("Invalid request")
                return
            }
            
            #expect(json["email"] == "bademail")
            #expect(json["role"] == "user")
        }
        
        //MARK: parseUserInviteResponse(data:response:)
        @Test("Parse user invite response returns true on 200")
        func testParseUserInviteResponseSuccess() throws {
            let api = DirectusAPI(baseURL: "https://example.com")
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/users/invite")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let result = try api.parseUserInviteResponse(data: Data(), response: response)
            #expect(result == true)
        }
        
        @Test("Parse user invite response returns false on non-200")
        func testParseUserInviteResponseFailure() throws {
            let api = DirectusAPI(baseURL: "https://example.com")
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/users/invite")!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            let result = try api.parseUserInviteResponse(data: Data(), response: response)
            #expect(result == false)
        }
        
        //MARK: preparePasswordChangeRequest(token:newPassword:)
        @Test("Prepare request for password change uses correct endpoint")
        func testPreparePasswordChangeRequestUsesCorrectEndpoint() throws {
            let api = DirectusAPI(baseURL: "https://example.com")
            let token = "abc123"
            let newPassword = "password"
            
            let prepared = try api.preparePasswordChangeRequest(
                token: token,
                newPassword: newPassword
            )
            
            guard let request = prepared.request as? URLRequest,
                  let body = request.httpBody,
                  let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
            else {
                XCTFail("Invalid request")
                return
            }
            
            #expect(request.url?.absoluteString == "https://example.com/auth/password/reset")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(json["token"] == "abc123")
            #expect(json["password"] == "password")
        }
        
        //MARK: preparePasswordResetRequest(email:resetUrl:)
        @Test("Prepare request for password reset uses correct endpoint")
        func testPreparePasswordResetRequestUsesCorrectEndpoint() throws {
            let api = DirectusAPI(baseURL: "https://example.com")
            let email = "abc123"
            
            let prepared = try api.preparePasswordResetRequest(email: email)
            
            guard let request = prepared.request as? URLRequest,
                  let body = request.httpBody,
                  let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
            else {
                XCTFail("Invalid request")
                return
            }
            
            #expect(request.url?.absoluteString == "https://example.com/auth/password/request")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(json["email"] == "abc123")
            #expect(json["reset_url"] == nil)
        }
        
        @Test("Prepare request for password reset with url uses correct endpoint")
        func testPreparePasswordResetRequestWithUrlUsesCorrectEndpoint() throws {
            let api = DirectusAPI(baseURL: "https://example.com")
            let email = "abc123"
            let resetUrl = "https://www.example.com/reset"
            
            let prepared = try api.preparePasswordResetRequest(
                email: email,
                resetUrl: resetUrl
            )
            
            guard let request = prepared.request as? URLRequest,
                  let body = request.httpBody,
                  let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
            else {
                XCTFail("Invalid request")
                return
            }
            
            #expect(request.url?.absoluteString == "https://example.com/auth/password/request")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(json["email"] == "abc123")
            #expect(json["reset_url"] == "https://www.example.com/reset")
        }
        
        //MARK: prepareGetCurrentUserRequest(fields:)
        @Test("Prepare get current user request uses me endpoint")
        func testPrepareGetCurrentUserRequestUsesMeEndpoint() {
            let api = DirectusAPI(baseURL: "https://example.com")
            let prepared = api.prepareGetCurrentUserRequest()
            guard let request = prepared.request as? URLRequest,
                  let urlString = request.url?.absoluteString else {
                XCTFail("prepared.request is not a URLRequest")
                return
            }
            #expect(urlString.contains("https://example.com/users/me"))
            #expect(urlString.contains("fields"))
        }
        
        @Test("Prepare get current user request with fields")
        func testPrepareGetCurrentUserRequestWithFields() {
            let api = DirectusAPI(baseURL: "https://example.com")
            let prepared = api.prepareGetCurrentUserRequest(
                fields: "id,name,email"
            )
            guard let request = prepared.request as? URLRequest,
                  let urlString = request.url?.absoluteString else {
                XCTFail("prepared.request is not a URLRequest")
                return
            }
            #expect(urlString.contains("https://example.com/users/me"))
            #expect(urlString.contains("fields=id,name,email"))
        }
    }
    
    @MainActor
    struct ItemsTests {
        
        @MainActor
        struct CreateNewItemTests {
            //MARK: prepareCreateNewItemRequest(endpointName:endpointPrefix:objectData:fields:)
            //TODO: Test function
            //MARK: parseCreateNewItemResponse(data:response:)
            //TODO: Test function
        }
        
        @MainActor
        struct GetSpecificItemTests {
            //MARK: prepareGetSpecificItemRequest(fields:endpointPrefix:endpointName:itemId:tags:)
            //TODO: Test function
            //MARK: parseGetSpecificItemResponse(data:response:)
            //TODO: Test function
        }
        
        @MainActor
        struct GetListOfItemsTests {
            //MARK: prepareGetListOfItemsRequest(endpointName:endpointPrefix:fields:filter:sortBy:limit:offset:)
            @Test("Prepare get list of items request")
            func testPrepareGetListOfItemsRequest() throws {
                let api = DirectusAPI(baseURL: "https://example.com")
                
                let prepared = api.prepareGetListOfItemsRequest(
                    endpointName: "test",
                    endpointPrefix: "/endpoint/"
                )
                
                guard let request = prepared.request as? URLRequest,
                      let urlString = request.url?.absoluteString else {
                    XCTFail("Failed to generate URLRequest")
                    return
                }
                
                // Assertions
                #expect(request.httpMethod == "GET")
                #expect(request.url?.scheme == "https")
                #expect(prepared.tags.isEmpty)
                #expect(urlString.contains("https://example.com/endpoint/test"))
                #expect(urlString.contains("fields=*"))
                #expect(urlString.contains("filter") == false)
                #expect(urlString.contains("limit") == false)
                #expect(urlString.contains("offset") == false)
                #expect(urlString.contains("sort") == false)
            }
            
            @Test("Prepare get list of items request with parameters")
            func testPrepareGetListOfItemsRequestWithParameters() throws {
                let api = DirectusAPI(baseURL: "https://example.com")
                
                let filter = PropertyFilter(field: "status", operator: .equals, value: "active")
                let sortBy = [
                    SortProperty(name: "created_at", ascending: false),
                    SortProperty(name: "name", ascending: true)
                ]
                let limit = 10
                let offset = 5
                
                let prepared = api.prepareGetListOfItemsRequest(
                    endpointName: "users",
                    endpointPrefix: "/",
                    fields: "id,name",
                    filter: filter,
                    sortBy: sortBy,
                    limit: limit,
                    offset: offset
                )
                
                guard let request = prepared.request as? URLRequest,
                      let urlString = request.url?.absoluteString else {
                    XCTFail("Failed to generate URLRequest")
                    return
                }
                
                // Assertions
                #expect(request.httpMethod == "GET")
                #expect(request.url?.scheme == "https")
                #expect(prepared.tags.isEmpty)
                #expect(urlString.contains("https://example.com/users"))
                #expect(urlString.contains("fields=id,name"))
                #expect(urlString.contains("filter="))
                #expect(urlString.contains("limit=10"))
                #expect(urlString.contains("offset=5"))
                #expect(urlString.contains("sort=-created_at,name"))
            }
            
            //MARK: parseGetListOfItemsResponse(data:response:)
            @Test("Parses valid list of items")
            func testParsesValidList() throws {
                let json = """
        {
            "data": [
                { "id": 1 },
                { "id": 2 }
            ]
        }
        """.data(using: .utf8)!
                
                let response = HTTPURLResponse(url: URL(string: "https://example.com/items")!,
                                               statusCode: 200,
                                               httpVersion: nil,
                                               headerFields: nil)!
                let api = DirectusAPI(baseURL: "https://example.com")
                let result = try api.parseGetListOfItemsResponse(data: json, response: response)
                #expect(result.count == 2)
                let resultArray = result as! [[String: Any]]
                #expect(resultArray[0]["id"] as? Int == 1)
                #expect(resultArray[1]["id"] as? Int == 2)
            }
            
            @Test("Returns empty list for missing data array")
            func testMissingDataReturnsEmpty() throws {
                let json = """
        {
            "message": "No data here"
        }
        """.data(using: .utf8)!
                
                do {
                    let response = HTTPURLResponse(url: URL(string: "https://example.com/items")!,
                                                   statusCode: 200,
                                                   httpVersion: nil,
                                                   headerFields: nil)!
                    let api = DirectusAPI(baseURL: "https://example.com")
                    _ = try api
                        .parseGetListOfItemsResponse(data: json, response: response)
                    XCTFail("Expected error to be thrown")
                } catch let error as DirectusApiError {
                    #expect(error.response?.statusCode == 200)
                    #expect(error.errorDescription == "No data here")
                } catch {
                    XCTFail("Unexpected error type: \(error)")
                }
            }
            
            @Test("Returns error message array on failed status code with message")
            func testReturnsErrorMessageOnFailure() throws {
                let json = """
        {
            "errors": [
                { "message": "Unauthorized" }
            ]
        }
        """.data(using: .utf8)!
                
                do {
                    let response = HTTPURLResponse(url: URL(string: "https://example.com/items")!,
                                                   statusCode: 401,
                                                   httpVersion: nil,
                                                   headerFields: nil)!
                    let api = DirectusAPI(baseURL: "https://example.com")
                    _ = try api
                        .parseGetListOfItemsResponse(data: json, response: response)
                    XCTFail("Expected error to be thrown")
                } catch let error as DirectusApiError {
                    #expect(error.response?.statusCode == 401)
                    #expect(error.errorDescription == "Unauthorized")
                } catch {
                    XCTFail("Unexpected error type: \(error)")
                }
            }
            
            @Test("Returns empty list on failed status code with no message")
            func testReturnsEmptyOnFailureWithoutMessage() throws {
                let json = """
        {
            "status": "error"
        }
        """.data(using: .utf8)!
                
                do {
                    let response = HTTPURLResponse(url: URL(string: "https://example.com/items")!,
                                                   statusCode: 500,
                                                   httpVersion: nil,
                                                   headerFields: nil)!
                    let api = DirectusAPI(baseURL: "https://example.com")
                    _ = try api
                        .parseGetListOfItemsResponse(data: json, response: response)
                    XCTFail("Expected error to be thrown")
                } catch let error as DirectusApiError {
                    #expect(error.response?.statusCode == 500)
                    #expect(error.errorDescription?.contains("DirectusApiError: Unexpected JSON format. Response: {\n    \"status\": \"error\"\n}") == true)
                } catch {
                    XCTFail("Unexpected error type: \(error)")
                }
            }
        }
        
        @MainActor
        struct UpdateItemTests {
            //MARK: prepareUpdateItemRequest(endpointName:endpointPrefix:itemId:objectData:fields:)
            //TODO: Test function
            //MARK: parseUpdateItemResponse(data:response:)
            //TODO: Test function
        }
        
        @MainActor
        struct DeleteItemTests {
            //MARK: prepareDeleteItemRequest(endpointName:itemId:endpointPrefix:mustBeAuthenticated:)
            //TODO: Test function
            //MARK: prepareDeleteMultipleItemRequest(endpointName:endpointPrefix:itemIdList:mustBeAuthenticated:)
            //TODO: Test function
        }
    }
    
    @MainActor
    struct FileTests {
        
        @MainActor
        struct FileUploadTests {
            //MARK: prepareNewFileUploadRequest(fileBytes:title:contentType:filename:folder:storage:)
            //TODO: Test function
            //MARK: parseFileUploadResponse(data:response:)
            //TODO: Test function
        }
        //MARK: prepareFileImportRequest(url:title:folder:)
        //TODO: Test function
        //MARK: prepareUpdateFileRequest(fileId:fileBytes:title:contentType:filename:)
        //TODO: Test function
        //MARK: prepareFileDeleteRequest(fileId:)
        //TODO: Test function
    }
    
    @MainActor
    struct GenericsTests {
        //MARK: parseGenericBoolResponse(data:response:)
        @Test("parseGenericBoolResponse succeeds on 2xx status code")
        func testParseGenericBoolResponseSuccess() throws {
            let api = DirectusAPI(baseURL: "https://example.com")
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/success")!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            let result = try api.parseGenericBoolResponse(data: Data(), response: response)
            #expect(result == true)
        }
        
        @Test("parseGenericBoolResponse throws on non-2xx status code")
        func testParseGenericBoolResponseFailure() throws {
            let api = DirectusAPI(baseURL: "https://example.com")
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/failure")!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = """
                {
                    "errors": [
                        {
                            "message": "Bad request"
                        }
                    ]
                }
                """.data(using: .utf8)!
            
            do {
                _ = try api.parseGenericBoolResponse(data: data, response: response)
                XCTFail("Expected error to be thrown")
            } catch let error as NSError {
                #expect(error.domain == "DirectusAPI")
                #expect(error.code == 400)
                #expect(error.localizedDescription.contains("Bad request"))
            }
        }
    }
}
