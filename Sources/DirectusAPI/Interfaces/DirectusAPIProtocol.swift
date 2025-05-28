//
//  DirectusAPIProtocol.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

@MainActor
public protocol DirectusAPIProtocol: Sendable {
    var shouldRefreshToken: Bool { get }
    var accessToken: String? { get }
    var currentAuthToken: String? { get }
    var refreshToken: String? { get set }
    var baseURL: String { get }
    var hasLoggedInUser: Bool { get }
    
    func authenticateRequest(_ request: inout URLRequest) -> URLRequest
    func prepareGetCurrentUserRequest(fields: String) -> PreparedRequest
    
    func prepareGetListOfItemsRequest(
        endpointName: String,
        endpointPrefix: String,
        fields: String,
        filter: Filter?,
        sortBy: [SortProperty]?,
        limit: Int?,
        offset: Int?
    ) -> PreparedRequest
    
    func parseGetListOfItemsResponse(data: Data, response: HTTPURLResponse) throws -> [Any]
    
    func prepareGetSpecificItemRequest(
        fields: String,
        endpointPrefix: String,
        endpointName: String,
        itemId: String,
        tags: [String]
    ) -> PreparedRequest
    
    func parseGetSpecificItemResponse(data: Data, response: HTTPURLResponse) throws -> Any
    
    func prepareCreateNewItemRequest(
        endpointName: String,
        endpointPrefix: String,
        objectData: Any,
        fields: String
    ) -> PreparedRequest
    
    func parseCreateNewItemResponse(data: Data, response: HTTPURLResponse) throws -> Any
    
    func prepareUpdateItemRequest(
        endpointName: String,
        endpointPrefix: String,
        itemId: String,
        objectData: Any,
        fields: String
    ) -> PreparedRequest
    
    func parseUpdateItemResponse(data: Data, response: HTTPURLResponse) throws -> Any
    
    func prepareDeleteItemRequest(
        endpointPrefix: String,
        endpointName: String,
        itemId: String,
        mustBeAuthenticated: Bool
    ) -> PreparedRequest
    
    func prepareDeleteMultipleItemRequest(
        endpointName: String,
        endpointPrefix: String,
        itemIdList: [Any],
        mustBeAuthenticated: Bool
    ) -> PreparedRequest
    
    func parseGenericBoolResponse(data: Data, response: HTTPURLResponse) throws -> Bool
    
    func prepareRefreshTokenRequest() async throws -> PreparedRequest
    func parseRefreshTokenResponse(data: Data, response: HTTPURLResponse) async throws -> Bool
    
    func prepareLogoutRequest() throws -> PreparedRequest?
    func parseLogoutResponse(data: Data, response: HTTPURLResponse) throws -> Bool
    
    func prepareLoginRequest(username: String, password: String, oneTimePassword: String?) throws -> PreparedRequest
    func parseLoginResponse(data: Data, response: HTTPURLResponse) async -> DirectusLoginResult
    
    func prepareUserInviteRequest(email: String, roleId: String) throws -> PreparedRequest
    func parseUserInviteResponse(data: Data, response: HTTPURLResponse) throws -> Bool
    
    func prepareFileDownloadRequest(fileId: String) throws -> PreparedRequest
    func prepareFileImportRequest(url: String, title: String?, folder: String?) throws -> PreparedRequest
    func prepareFileDeleteRequest(fileId: String) throws -> PreparedRequest
    func prepareNewFileUploadRequest(
        fileBytes: [UInt8],
        title: String?,
        contentType: String?,
        filename: String,
        folder: String?,
        storage: String
    ) throws -> PreparedRequest
    func prepareUpdateFileRequest(
        fileId: String,
        fileBytes: [UInt8]?,
        title: String?,
        contentType: String?,
        filename: String
    ) throws -> PreparedRequest
    func parseFileDownloadResponse(data: Data, response: HTTPURLResponse) throws -> Data
    func parseFileUploadResponse(data: Data, response: HTTPURLResponse) throws -> DirectusFile
    
    func convertPathToFullURL(path: String) -> String
    
    func preparePasswordResetRequest(email: String, resetUrl: String?) throws -> PreparedRequest
    func preparePasswordChangeRequest(token: String, newPassword: String) throws -> PreparedRequest
    
    func prepareRegisterUserRequest(
        email: String,
        password: String,
        firstname: String?,
        lastname: String?
    ) throws -> PreparedRequest
}
