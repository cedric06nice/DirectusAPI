//
//  DirectusApiManagerProtocol.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

@MainActor
public protocol DirectusApiManagerProtocol: Sendable {

    // Token Management
    var shouldRefreshToken: Bool { get }
    var accessToken: String? { get }
    var refreshToken: String? { get set }
    
    func tryAndRefreshToken() async throws -> Bool
    
    // WebSocket and Base URL
    var webSocketBaseUrl: String { get }
    var baseURL: String { get }

    // Authentication
    func loginDirectusUser(username: String, password: String, oneTimePassword: String?) async throws -> DirectusLoginResult
    func logoutDirectusUser() async throws -> Bool
    func registerDirectusUser(email: String, password: String, firstname: String?, lastname: String?) async throws -> Bool
    func hasLoggedInUser() async throws -> Bool
    func currentDirectusUser(fields: String, canUseCache: Bool, canSaveCache: Bool, fallbackToStaleCache: Bool, maxCacheAge: TimeInterval) async throws -> DirectusUser?

    // Password Reset
    func requestPasswordReset(email: String, resetUrl: String?) async throws -> Bool
    func confirmPasswordReset(token: String, password: String) async throws -> Bool

    // CRUD Operations
    func findListOfItems<T: DirectusData & DirectusCollection>(
        filter: Filter?,
        sortBy: [SortProperty]?,
        fields: String?,
        limit: Int?,
        offset: Int?,
        requestIdentifier: String?,
        canUseCache: Bool,
        canSaveCache: Bool,
        fallbackToStaleCache: Bool,
        maxCacheAge: TimeInterval
    ) async throws -> [T]

    func findListOfItemsWithResult<T: DirectusData & DirectusCollection>(
        filter: Filter?,
        sortBy: [SortProperty]?,
        fields: String?,
        limit: Int?,
        offset: Int?,
        requestIdentifier: String?,
        canUseCache: Bool,
        canSaveCache: Bool,
        fallbackToStaleCache: Bool,
        maxCacheAge: TimeInterval
    ) async -> Result<[T], Error>

    func getSpecificItem<T: DirectusData & DirectusCollection>(
        id: String,
        fields: String?,
        requestIdentifier: String?,
        canUseCache: Bool,
        canSaveCache: Bool,
        fallbackToStaleCache: Bool,
        maxCacheAge: TimeInterval
    ) async throws -> T?

    func createNewItem<T: DirectusData & DirectusCollection>(
        objectToCreate: T,
        fields: String?
    ) async throws -> DirectusItemCreationResult<T>

    func createMultipleItems<T: DirectusData & DirectusCollection>(
        objectList: [T],
        fields: String?
    ) async throws -> DirectusItemCreationResult<T>

    func updateItem<T: DirectusData & DirectusCollection>(
        objectToUpdate: T,
        fields: String?,
        force: Bool
    ) async throws -> T

    func deleteItem<T>(objectId: String, ofType type: T.Type, mustBeAuthenticated: Bool) async throws -> Bool where T : DirectusData, T : DirectusCollection

    func deleteMultipleItems<T>(objectIdsToDelete: [Any], ofType type: T.Type, mustBeAuthenticated: Bool) async throws -> Bool where T : DirectusData, T : DirectusCollection

    // File Handling
    func getFile(fileId: String) async throws -> Data
    
    func uploadFileFromUrl(
        remoteUrl: String,
        title: String?,
        folder: String?
    ) async throws -> DirectusFile

    func uploadFile(
        fileBytes: [UInt8],
        filename: String,
        title: String?,
        contentType: String?,
        folder: String?,
        storage: String
    ) async throws -> DirectusFile

    func updateExistingFile(
        fileBytes: [UInt8],
        fileId: String,
        filename: String,
        contentType: String?
    ) async throws -> DirectusFile

    func deleteFile(fileId: String) async throws -> Bool

    // Generic Request
    func sendRequestToEndpoint<T>(prepareRequest: () -> URLRequest,
                                  jsonConverter: @escaping (HTTPURLResponse, Data) throws -> T,
                                  requestIdentifier: String?,
                                  canUseCacheForResponse: Bool,
                                  canSaveResponseToCache: Bool,
                                  canUseOldCachedResponseAsFallback: Bool,
                                  maxCacheAge: TimeInterval) async throws -> T
}
