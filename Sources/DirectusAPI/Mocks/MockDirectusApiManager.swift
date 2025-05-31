//
//  MockDirectusApiManager.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

@MainActor
final class MockDirectusApiManager: DirectusApiManagerProtocol {
    
    // Token Management
    var shouldRefreshToken: Bool = false
    var accessToken: String? = "mock-token"
    var refreshToken: String? = "mock-refresh-token"

    func tryAndRefreshToken() async -> Bool {
        recordCall("tryAndRefreshToken")
        return dequeueReturn() ?? true
    }
    
    // WebSocket and Base URL
    var webSocketBaseUrl: String {
        "ws://mock.api/ws"
    }
    var baseURL: String {
        "http://mock.api"
    }
    
    var calledMethods: [String] = []
    var receivedArguments: [String: Any] = [:]
    var returnQueue: [Any?] = []
    
    func enqueueReturn<T>(_ value: T?) {
        returnQueue.append(value)
    }
    
    private func dequeueReturn<T>(as type: T.Type = T.self) -> T? {
        guard !returnQueue.isEmpty else { return nil }
        return returnQueue.removeFirst() as? T
    }
    
    private func recordCall(_ method: String, args: [String: Any] = [:]) {
        calledMethods.append(method)
        for (k, v) in args {
            receivedArguments[k] = v
        }
    }
    
    // Authentication
    func loginDirectusUser(username: String, password: String, oneTimePassword: String?) async throws -> DirectusLoginResult {
        recordCall(
            "loginDirectusUser",
            args: [
                "username": username,
                "password": password,
                "otp": oneTimePassword as Any
            ]
        )
        return dequeueReturn() ?? DirectusLoginResult(type: .error, message: "Mock: no return value")
    }
    
    func logoutDirectusUser() async throws -> Bool {
        recordCall("logoutDirectusUser")
        guard let value = dequeueReturn(as: Bool.self) else {
            throw MockResultError()
        }
        return value
    }
    
    func registerDirectusUser(email: String, password: String, firstname: String?, lastname: String?) async throws -> Bool {
        recordCall(
            "registerDirectusUser", args: [
                "email": email,
                "password": password,
                "firstname": firstname as Any,
                "lastname": lastname as Any
            ]
        )
        guard let value = dequeueReturn(as: Bool.self) else {
            throw MockResultError()
        }
        return value
    }
    
    func hasLoggedInUser() async throws -> Bool {
        recordCall("hasLoggedInUser")
        guard let value = dequeueReturn(as: Bool.self) else {
            throw MockResultError()
        }
        return value
    }
    
    func currentDirectusUser(fields: String = "*", canUseCache: Bool, canSaveCache: Bool, fallbackToStaleCache: Bool, maxCacheAge: TimeInterval) async throws -> DirectusUser? {
        recordCall("currentDirectusUser", args: ["fields": fields])
        guard let value = dequeueReturn(as: DirectusUser.self) else {
            throw MockResultError()
        }
        return value
    }

    // Password Reset
    func requestPasswordReset(email: String, resetUrl: String?) async throws -> Bool {
        recordCall( "requestPasswordReset", args: ["email": email])
        guard let value = dequeueReturn(as: Bool.self) else {
            throw MockResultError()
        }
        return value
    }
    
    func confirmPasswordReset(token: String, password: String) async throws -> Bool {
        recordCall( "confirmPasswordReset", args: ["token": token, "password": password])
        guard let value = dequeueReturn(as: Bool.self) else {
            throw MockResultError()
        }
        return value
    }
    

    // CRUD Operations
    func findListOfItems<T>(filter: (any Filter)?, sortBy: [SortProperty]?, fields: String?, limit: Int?, offset: Int?, requestIdentifier: String?, canUseCache: Bool, canSaveCache: Bool, fallbackToStaleCache: Bool, maxCacheAge: TimeInterval) async throws -> [T] where T : DirectusData, T : DirectusCollection {
        recordCall(
            "findListOfItems",
            args: [
                "filter": filter as Any,
                "sortBy": sortBy as Any,
                "fields": fields as Any,
                "limit": limit as Any,
                "offset": offset as Any,
                "requestIdentifier": requestIdentifier as Any,
                "canUseCache": canUseCache,
                "canSaveCache": canSaveCache,
                "fallbackToStaleCache": fallbackToStaleCache,
                "maxCacheAge": maxCacheAge
            ]
        )
        guard let value = dequeueReturn(as: [T].self) else {
            throw MockResultError()
        }
        return value
    }
    
    func findListOfItemsWithResult<T>(filter: (any Filter)?, sortBy: [SortProperty]?, fields: String?, limit: Int?, offset: Int?, requestIdentifier: String?, canUseCache: Bool, canSaveCache: Bool, fallbackToStaleCache: Bool, maxCacheAge: TimeInterval) async -> MockResult<[T]> where T : DirectusData, T : DirectusCollection {
        recordCall(
            "findListOfItemsWithResult",
            args: [
                "filter": filter as Any,
                "sortBy": sortBy as Any,
                "fields": fields as Any,
                "limit": limit as Any,
                "offset": offset as Any,
                "requestIdentifier": requestIdentifier as Any,
                "canUseCache": canUseCache,
                "canSaveCache": canSaveCache,
                "fallbackToStaleCache": fallbackToStaleCache,
                "maxCacheAge": maxCacheAge as Any
            ]
        )
        return dequeueReturn(as: MockResult<[T]>.self) ??
            .failure(MockResultError())
    }
    
    func getSpecificItem<T>(id: String, fields: String?, requestIdentifier: String?, canUseCache: Bool, canSaveCache: Bool, fallbackToStaleCache: Bool, maxCacheAge: TimeInterval) async throws -> T? where T : DirectusData, T : DirectusCollection {
        recordCall(
            "getSpecificItem",
            args: [
                "id": id,
                "fields": fields as Any,
                "requestIdentifier": requestIdentifier as Any,
                "canUseCache": canUseCache,
                "canSaveCache": canSaveCache,
                "fallbackToStaleCache": fallbackToStaleCache,
                "maxCacheAge": maxCacheAge
            ]
        )
        guard let value = dequeueReturn(as: T.self) else {
            throw MockResultError()
        }
        return value
    }
    
    func createNewItem<T>(objectToCreate: T, fields: String?) async throws -> DirectusItemCreationResult<T> where T : DirectusData, T : DirectusCollection {
        recordCall(
            "createNewItem",
            args: [
                "objectToCreate": objectToCreate,
                "fields": fields as Any
            ]
        )
        guard let value = dequeueReturn(as: DirectusItemCreationResult<T>.self) else {
            throw MockResultError()
        }
        return value
    }
    
    func createMultipleItems<T>(objectList: [T], fields: String?) async throws -> DirectusItemCreationResult<T> where T : DirectusData, T : DirectusCollection {
        recordCall(
            "createMultipleItems",
            args: [
                "objectList": objectList,
                "fields": fields as Any
            ]
        )
        guard let value = dequeueReturn(as: DirectusItemCreationResult<T>.self) else {
            throw MockResultError()
         }
        return value
    }
    
    func updateItem<T>(objectToUpdate: T, fields: String?, force: Bool) async throws -> T where T : DirectusData, T : DirectusCollection {
        recordCall(
            "updateItem",
            args: [
                "objectToUpdate": objectToUpdate,
                "fields": fields as Any,
                "force": force
            ]
        )
        guard let value = dequeueReturn(as: T.self) else {
            throw MockResultError()
        }
        return value
    }
    
    func deleteItem<T>(objectId: String, ofType type: T.Type, mustBeAuthenticated: Bool) async throws -> Bool where T : DirectusData, T : DirectusCollection {
        recordCall(
            "deleteItem",
            args: [
                "objectId": objectId,
                "ofType": type,
                "mustBeAuthenticated": mustBeAuthenticated
            ]
        )
        guard let value = dequeueReturn(as: Bool.self) else {
            throw MockResultError()
        }
        return value
    }
    
    func deleteMultipleItems<T>(objectIdsToDelete: [Any], ofType type: T.Type, mustBeAuthenticated: Bool) async throws -> Bool where T : DirectusData, T : DirectusCollection {
        recordCall(
            "deleteMultipleItems",
            args: [
                "objectIdsToDelete": objectIdsToDelete,
                "ofType": type,
                "mustBeAuthenticated": mustBeAuthenticated
            ]
        )
        guard let value = dequeueReturn(as: Bool.self) else {
            throw MockResultError()
        }
        return value
    }
    
    func getFile(fileId: String) async throws -> Data {
        recordCall(
            "getFile",
            args: ["fileId": fileId]
        )
        guard let value = dequeueReturn(as: Data.self) else {
            throw MockResultError()
        }
        return value
    }
    
    func uploadFileFromUrl(remoteUrl: String, title: String?, folder: String?) async throws -> DirectusFile {
        recordCall(
            "uploadFileFromUrl",
            args: [
                "remoteUrl": remoteUrl,
                "title": title as Any,
                "folder": folder as Any
            ]
        )
        guard let value = dequeueReturn(as: DirectusFile.self) else {
            throw MockResultError()
        }
        return value
    }
    
    func uploadFile(fileBytes: [UInt8], filename: String, title: String?, contentType: String?, folder: String?, storage: String) async throws -> DirectusFile {
        recordCall(
            "uploadFile",
            args: [
                "fileBytes": fileBytes,
                "filename": filename,
                "title": title as Any,
                "contentType": contentType as Any,
                "folder": folder as Any,
                "storage": storage
            ]
        )
        guard let value = dequeueReturn(as: DirectusFile.self) else {
            throw MockResultError()
        }
        return value
    }
    
    func updateExistingFile(fileBytes: [UInt8], fileId: String, filename: String, contentType: String?) async throws -> DirectusFile {
        recordCall(
            "updateExistingFile",
            args: [
                "fileBytes": fileBytes,
                "fileId": fileId,
                "filename": filename,
                "contentType": contentType as Any
                ]
            )
        guard let value = dequeueReturn(as: DirectusFile.self) else {
            throw MockResultError()
        }
        return value
    }
    
    func deleteFile(fileId: String) async throws -> Bool {
        recordCall(
            "deleteFile",
            args: ["fileId": fileId]
        )
        guard let value = dequeueReturn(as: Bool.self) else {
            throw MockResultError()
        }
        return value
    }
    
    func sendRequestToEndpoint<T>(prepareRequest: () -> URLRequest, jsonConverter: @escaping (HTTPURLResponse, Data) throws -> T, requestIdentifier: String?, canUseCacheForResponse: Bool, canSaveResponseToCache: Bool, canUseOldCachedResponseAsFallback: Bool, maxCacheAge: TimeInterval) async throws -> T {
        recordCall(
            "sendRequestToEndpoint",
            args: [
                "requestIdentifier": requestIdentifier as Any,
                "canUseCacheForResponse": canUseCacheForResponse,
                "canSaveResponseToCache": canSaveResponseToCache,
                "canUseOldCachedResponseAsFallback": canUseOldCachedResponseAsFallback,
                "maxCacheAge": maxCacheAge
            ]
        )
        guard let value = dequeueReturn(as: T.self) else {
            throw MockResultError()
        }
        return value
    }
}

struct MockResultError: Error {}
typealias MockResult<T> = Result<T, Error>
