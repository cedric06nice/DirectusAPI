//
//  MockDirectusApi.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

final class MockDirectusApi: DirectusAPIProtocol {
    var shouldRefreshToken: Bool = false
    var accessToken: String? = nil
    var currentAuthToken: String? = nil
    var refreshToken: String? = nil
    var baseURL: String = "https://example.com"
    var nextParsedResponse: Any?
    
    init() {}
    
    func parseCreateNewItemResponse(data: Data, response: HTTPURLResponse) throws -> Any {
        guard let value = nextParsedResponse else {
            throw DirectusApiError(response: nil, bodyData: nil, customMessage: "No value")
        }
        return value
    }
    
    var hasLoggedInUser: Bool { false }
    
    func authenticateRequest(_ request: inout URLRequest) -> URLRequest { request }
    
    func prepareGetCurrentUserRequest(fields: String) -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func prepareGetListOfItemsRequest(endpointName: String, endpointPrefix: String, fields: String, filter: Filter?, sortBy: [SortProperty]?, limit: Int?, offset: Int?) -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func parseGetListOfItemsResponse(data: Data, response: HTTPURLResponse) throws -> [Any] { [] }
    
    func prepareGetSpecificItemRequest(fields: String, endpointPrefix: String, endpointName: String, itemId: String, tags: [String]) -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func parseGetSpecificItemResponse(data: Data, response: HTTPURLResponse) throws -> Any { [:] }
    
    func prepareCreateNewItemRequest(endpointName: String, endpointPrefix: String, objectData: Any, fields: String) -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func prepareUpdateItemRequest(endpointName: String, endpointPrefix: String, itemId: String, objectData: Any, fields: String) -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func parseUpdateItemResponse(data: Data, response: HTTPURLResponse) throws -> Any { [:] }
    
    func prepareDeleteItemRequest(endpointPrefix: String, endpointName: String, itemId: String,  mustBeAuthenticated: Bool) -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func prepareDeleteMultipleItemRequest(endpointName: String, endpointPrefix: String, itemIdList: [Any], mustBeAuthenticated: Bool) -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func parseGenericBoolResponse(data: Data, response: HTTPURLResponse) throws -> Bool { true }
    
    func prepareRefreshTokenRequest() async throws -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func parseRefreshTokenResponse(data: Data, response: HTTPURLResponse) async throws -> Bool { true }
    
    func prepareLogoutRequest() throws -> PreparedRequest? {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func parseLogoutResponse(data: Data, response: HTTPURLResponse) throws -> Bool { true }
    
    func prepareLoginRequest(username: String, password: String, oneTimePassword: String?) throws -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func parseLoginResponse(data: Data, response: HTTPURLResponse) async -> DirectusLoginResult {
        self.accessToken = "token"
        self.refreshToken = "refresh"
        return DirectusLoginResult(type: .success)
    }
    
    func prepareUserInviteRequest(email: String, roleId: String) throws -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func parseUserInviteResponse(data: Data, response: HTTPURLResponse) throws -> Bool { true }
    
    func prepareFileDownloadRequest(fileId: String) throws -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func prepareFileImportRequest(url: String, title: String?, folder: String?) throws -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func prepareFileDeleteRequest(fileId: String) throws -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func prepareNewFileUploadRequest(fileBytes: [UInt8], title: String?, contentType: String?, filename: String, folder: String?, storage: String) throws -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func prepareUpdateFileRequest(fileId: String, fileBytes: [UInt8]?, title: String?, contentType: String?, filename: String) throws -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func parseFileDownloadResponse(data: Data, response: HTTPURLResponse) throws -> Data {
        Data()
    }
    
    func parseFileUploadResponse(data: Data, response: HTTPURLResponse) throws -> DirectusFile {
        try DirectusFile(["id": "mock"])
    }
    
    func convertPathToFullURL(path: String) -> String {
        baseURL + "/" + path
    }
    
    func preparePasswordResetRequest(email: String, resetUrl: String?) throws -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func preparePasswordChangeRequest(token: String, newPassword: String) throws -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
    
    func prepareRegisterUserRequest(email: String, password: String, firstname: String?, lastname: String?) throws -> PreparedRequest {
        PreparedRequest(request: URLRequest(url: URL(string: baseURL)!))
    }
}
