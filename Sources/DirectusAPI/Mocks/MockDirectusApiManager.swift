//
//  MockDirectusApiManager.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

@MainActor
@Observable
public final class MockDirectusApiManager: DirectusApiManagerProtocol {
    public init() {}

    // MARK: - Storage
    public var calledFunctions: [String] = []
    public var receivedArguments: [String: Any] = [:]
    public var returnValues: [Any] = []

    private func addCall(_ name: String, args: [String: Any] = [:]) {
        calledFunctions.append(name)
        for (k, v) in args {
            receivedArguments[k] = v
        }
    }

    private func nextReturn<T>() -> T {
        return returnValues.removeFirst() as! T
    }

    // MARK: - Protocol Implementations

    public var shouldRefreshToken: Bool = false
    public var accessToken: String? = "ABCD.1234.ABCD"
    public var refreshToken: String? = "refreshToken"
    public var webSocketBaseUrl: String = ""
    public var baseURL: String = "http://api.com:8055"

    public func tryAndRefreshToken() async throws -> Bool {
        addCall("tryAndRefreshToken")
        return nextReturn()
    }

    public func loginDirectusUser(username: String, password: String, oneTimePassword: String?) async throws -> DirectusLoginResult {
        addCall("loginDirectusUser", args: ["username": username, "password": password, "otp": oneTimePassword as Any])
        return nextReturn()
    }

    public func logoutDirectusUser() async throws -> Bool {
        addCall("logoutDirectusUser")
        return nextReturn()
    }

    public func registerDirectusUser(email: String, password: String, firstname: String?, lastname: String?) async throws -> Bool {
        addCall("registerDirectusUser", args: ["email": email, "password": password, "firstname": firstname as Any, "lastname": lastname as Any])
        return nextReturn()
    }

    public func hasLoggedInUser() async throws -> Bool {
        addCall("hasLoggedInUser")
        return nextReturn()
    }

    public func currentDirectusUser(fields: String, canUseCache: Bool, canSaveCache: Bool, fallbackToStaleCache: Bool, maxCacheAge: TimeInterval) async throws -> DirectusUser? {
        addCall("currentDirectusUser", args: ["fields": fields])
        return nextReturn()
    }

    public func requestPasswordReset(email: String, resetUrl: String?) async throws -> Bool {
        addCall("requestPasswordReset", args: ["email": email, "resetUrl": resetUrl as Any])
        return nextReturn()
    }

    public func confirmPasswordReset(token: String, password: String) async throws -> Bool {
        addCall("confirmPasswordReset", args: ["token": token, "password": password])
        return nextReturn()
    }

    public func findListOfItems<T>(filter: Filter?, sortBy: [SortProperty]?, fields: String?, limit: Int?, offset: Int?, requestIdentifier: String?, canUseCache: Bool, canSaveCache: Bool, fallbackToStaleCache: Bool, maxCacheAge: TimeInterval) async throws -> [T] where T : DirectusData, T : DirectusCollection {
        addCall("findListOfItems")
        return nextReturn()
    }

    public func findListOfItemsWithResult<T>(filter: Filter?, sortBy: [SortProperty]?, fields: String?, limit: Int?, offset: Int?, requestIdentifier: String?, canUseCache: Bool, canSaveCache: Bool, fallbackToStaleCache: Bool, maxCacheAge: TimeInterval) async -> Result<[T], Error> where T : DirectusData, T : DirectusCollection {
        addCall("findListOfItemsWithResult")
        return nextReturn()
    }

    public func getSpecificItem<T>(id: String, fields: String?, requestIdentifier: String?, canUseCache: Bool, canSaveCache: Bool, fallbackToStaleCache: Bool, maxCacheAge: TimeInterval) async throws -> T? where T : DirectusData, T : DirectusCollection {
        addCall("getSpecificItem", args: ["id": id])
        return nextReturn()
    }

    public func createNewItem<T>(objectToCreate: T, fields: String?) async throws -> DirectusItemCreationResult<T> where T : DirectusData, T : DirectusCollection {
        addCall("createNewItem", args: ["objectToCreate": objectToCreate])
        return nextReturn()
    }

    public func createMultipleItems<T>(objectList: [T], fields: String?) async throws -> DirectusItemCreationResult<T> where T : DirectusData, T : DirectusCollection {
        addCall("createMultipleItems", args: ["objectList": objectList])
        return nextReturn()
    }

    public func updateItem<T>(objectToUpdate: T, fields: String?, force: Bool) async throws -> T where T : DirectusData, T : DirectusCollection {
        addCall("updateItem", args: ["objectToUpdate": objectToUpdate])
        return nextReturn()
    }

    public func deleteItem<T>(objectId: String, ofType type: T.Type, mustBeAuthenticated: Bool) async throws -> Bool where T : DirectusData, T : DirectusCollection {
        addCall("deleteItem", args: ["objectId": objectId])
        return nextReturn()
    }

    public func deleteMultipleItems<T>(objectIdsToDelete: [Any], ofType type: T.Type, mustBeAuthenticated: Bool) async throws -> Bool where T : DirectusData, T : DirectusCollection {
        addCall("deleteMultipleItems", args: ["objectIdsToDelete": objectIdsToDelete])
        return nextReturn()
    }
    public func getFile(fileId: String) async throws -> Data {
        addCall("getFile", args: ["fileId": fileId])
        return nextReturn()
    }

    public func uploadFileFromUrl(remoteUrl: String, title: String?, folder: String?) async throws -> DirectusFile {
        addCall("uploadFileFromUrl", args: ["remoteUrl": remoteUrl])
        return nextReturn()
    }

    public func uploadFile(fileBytes: [UInt8], filename: String, title: String?, contentType: String?, folder: String?, storage: String) async throws -> DirectusFile {
        addCall("uploadFile", args: ["filename": filename])
        return nextReturn()
    }

    public func updateExistingFile(fileBytes: [UInt8], fileId: String, filename: String, contentType: String?) async throws -> DirectusFile {
        addCall("updateExistingFile", args: ["fileId": fileId])
        return nextReturn()
    }

    public func deleteFile(fileId: String) async throws -> Bool {
        addCall("deleteFile", args: ["fileId": fileId])
        return nextReturn()
    }

    public func sendRequestToEndpoint<T>(
        prepareRequest: () -> URLRequest,
        jsonConverter: @escaping (HTTPURLResponse, Data) throws -> T,
        requestIdentifier: String?,
        canUseCacheForResponse: Bool,
        canSaveResponseToCache: Bool,
        canUseOldCachedResponseAsFallback: Bool,
        maxCacheAge: TimeInterval
    ) async throws -> T {
        addCall("sendRequestToEndpoint")
        return nextReturn()
    }
}
