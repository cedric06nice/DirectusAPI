//
//  DirectusApiManager.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import SwiftUI

@MainActor
@Observable
public final class DirectusApiManager: DirectusApiManagerProtocol {
    private let _httpClient: URLSession
    private var _api: DirectusAPIProtocol
    //    private let _metadataGenerator = MetadataGenerator()
    //    private var _refreshTask: Task<Void, Never>?
    
    private let _cacheEngine: LocalDirectusCacheProtocol?
    
    public private(set) var cachedCurrentUser: DirectusUser?
    
    public var shouldRefreshToken: Bool {
        return _api.shouldRefreshToken
    }
    
    public var accessToken: String? {
        return _api.accessToken
    }
    
    public var refreshToken: String? {
        get { _api.refreshToken }
        set { _api.refreshToken = newValue }
    }
    
    public var webSocketBaseUrl: String {
        var url = _api.baseURL
        if url.hasSuffix("/") {
            url.removeLast()
        }
        if url.starts(with: "http") {
            return url.replacingOccurrences(of: "http", with: "ws", options: .anchored) + "/websocket"
        }
        fatalError("Invalid base URL")
    }
    
    public var baseURL: String {
        return _api.baseURL
    }
    
    /// Creates a new DirectusApiManager instance.
    /// [baseURL] : The base URL of the Directus instance
    /// [httpClient] : The URLSession to use. If not provided, a new [URLSession] will be created.
    /// [saveRefreshTokenCallback] : A function that will be called when a new refresh token is received from the server. The function should save the token for later use.
    /// [loadRefreshTokenCallback] : A function that will be called when a new refresh token is needed to be sent to the server. The function should return the saved token.
    /// [cacheEngine] : Fill the property to aumtomatically have a configurable local cache
    /// You can use the already provided [JsonCacheEngine] to have an already implemented cache.
    /// Or you can create your own engine by extending [LocalDirectusCacheProtocol] an providing an instance of your engine in this property
    public init(
        baseURL: String,
        httpClient: URLSession = .shared,
        cacheEngine: LocalDirectusCacheProtocol? = nil,
        directusAPI: DirectusAPIProtocol? = nil,
        saveRefreshTokenCallback: ((String) async -> Void)? = nil,
        loadRefreshTokenCallback: (() async -> String?)? = nil
    ) {
        self._httpClient = httpClient
        self._cacheEngine = cacheEngine
        
        let normalizedURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        
        self._api = directusAPI ?? DirectusAPI(
            baseURL: normalizedURL,
            saveRefreshToken: (saveRefreshTokenCallback != nil)
            ? saveRefreshTokenCallback
            : { token in
                KeychainStorage.saveRefreshToken(token)
            },
            loadRefreshToken: (loadRefreshTokenCallback != nil)
            ? loadRefreshTokenCallback
            : { KeychainStorage.loadRefreshToken() }
        )
        DirectusFile.baseUrl = baseURL
    }
    
    /// Handles request preparation, sending and parsing.
    ///
    /// [prepareRequest] : A function that prepares and returns the HTTP request to send
    /// [parseResponse] : A function that receives the HTTP response from the server and returns the final function result.
    ///
    /// Returns the result from the [parseResponse] call.
    ///
    /// Throws an exception if [prepareRequest] returns null or not a [URLRequest] object
    private func _sendRequest<ResponseType: Sendable>(
        prepareRequest: () async throws -> PreparedRequest,
        parseResponse: (HTTPURLResponse, Data) async throws -> ResponseType,
        dependsOnToken: Bool = true,
        requestIdentifier: String? = nil,
        canUseCacheForResponse: Bool = false,
        canSaveResponseToCache: Bool = true,
        canUseOldCachedResponseAsFallback: Bool = true,
        maxCacheAge: TimeInterval = 86400
    ) async throws -> ResponseType {
        if dependsOnToken, _api.shouldRefreshToken {
            _ = try await tryAndRefreshToken()
        }
        
        let prepared = try await prepareRequest()
        let requestAny = prepared.request
        
        let request: URLRequest
        if let req = requestAny as? URLRequest {
            request = req
        } else if let futureReq = requestAny as? () async throws -> URLRequest {
            request = try await futureReq()
        } else {
            print("Invalid request: \(requestAny)")
            throw URLError(.badURL)
        }
        
        let cacheKey = requestIdentifier ?? "\(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")"
        var cacheEntry: CacheEntry?
        
        if let engine = _cacheEngine, canUseCacheForResponse {
            cacheEntry = try await engine.getCacheEntry(key: cacheKey)
            if let cached = cacheEntry, cached.validUntil > Date() {
                let (cachedResponse, cachedData) = cached.toURLResponse(url: request.url!)
                return try await parseResponse(cachedResponse!, cachedData)
            }
        }
        
        do {
            let (data, urlResponse) = try await URLSession.shared.data(for: request)
            guard let response = urlResponse as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            if canSaveResponseToCache, let engine = _cacheEngine {
                let entry = CacheEntry(
                    key: cacheKey,
                    dateCreated: Date(),
                    validUntil: Date().addingTimeInterval(maxCacheAge),
                    headers: response.allHeaderFields.compactMapKeys { $0 as? String },
                    body: String(data: data, encoding: .utf8) ?? "",
                    statusCode: response.statusCode
                )
                try await engine.setCacheEntry(cacheEntry: entry, tags: prepared.tags)
            }
            
            return try await parseResponse(response, data)
        } catch {
            if canUseOldCachedResponseAsFallback, let engine = _cacheEngine {
                if cacheEntry == nil {
                    cacheEntry = try await engine.getCacheEntry(key: cacheKey)
                }
                if let stale = cacheEntry, let url = request.url {
                    let (cachedResponse, cachedData) = stale.toURLResponse(url: url)
                    return try await parseResponse(cachedResponse!, cachedData)
                }
            }
            
            throw URLError(.badServerResponse)
        }
    }
    
    public var httpRequest: URLSession {
        return _httpClient
    }
    
    public func hasLoggedInUser() async throws -> Bool {
        do {
            _ = try await _api.prepareRefreshTokenRequest()
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    private var _refreshTokenLock: Task<Bool, Never>?
    
    public func tryAndRefreshToken() async throws -> Bool {
        if let lock = _refreshTokenLock {
            return await lock.value
        }
        
        let task = Task<Bool, Never> {
            defer { _refreshTokenLock = nil }
            
            do {
                let preparedRequest: PreparedRequest = try await _api.prepareRefreshTokenRequest()
                return try await _sendRequest(
                    prepareRequest: { preparedRequest },
                    parseResponse: { (response, data) in
                        try await _api
                            .parseRefreshTokenResponse(
                                data: data,
                                response: response
                            )
                    },
                    dependsOnToken: false,
                    canSaveResponseToCache: false
                )
            } catch {
                print("Refresh token error: \(error)")
            }
            return false
        }
        
        _refreshTokenLock = nil
        return await task.value
    }
    
    /// Logs in a user with the given [username], [password] and optional [oneTimePassword].
    /// Returns a Future [DirectusLoginResult] object that contains the result of the login attempt.
    public func loginDirectusUser(username: String, password: String, oneTimePassword: String?) async throws -> DirectusLoginResult {
        discardCurrentUserCache()
        
        return try await _sendRequest(
            prepareRequest: {
                try _api.prepareLoginRequest(
                    username: username,
                    password: password,
                    oneTimePassword: oneTimePassword
                )
            },
            parseResponse: { response, data in
                await _api.parseLoginResponse(data: data, response: response)
            },
            dependsOnToken: false,
            canUseCacheForResponse: false,
            canSaveResponseToCache: false,
            canUseOldCachedResponseAsFallback: false
        )
    }
    
    private var currentUserLock: Task<DirectusUser?, any Error>?
    private let currentUserCacheKey = "currentDirectusUser"
    
    /// Returns all the information about the currently logged in user.
    /// Returns null if no user is logged in.
    /// [fields] : A comma separated list of fields to return. If not provided, all fields will be returned.
    public func currentDirectusUser(
        fields: String = "*",
        canUseCache: Bool = false,
        canSaveCache: Bool = true,
        fallbackToStaleCache: Bool = true,
        maxCacheAge: TimeInterval = 86400
    ) async throws -> DirectusUser? {
        if let existingLock = currentUserLock {
            return try await existingLock.value
        }
        
        let task = Task<DirectusUser?, any Error>(priority: .none) {
            defer { currentUserLock = nil }
            
            if let user = cachedCurrentUser {
                return user
            }
            
            guard try await hasLoggedInUser() else {
                throw URLError(.userAuthenticationRequired)
            }
            
            do {
                let user = try await _sendRequest(
                    prepareRequest: { _api.prepareGetCurrentUserRequest(fields: fields) },
                    parseResponse: {
                        response,
                        data in
                        let json = try _api.parseGetSpecificItemResponse(data: data, response: response)
                        return try DirectusUser(json as! [String: Any])
                    },
                    requestIdentifier: currentUserCacheKey,
                    canUseCacheForResponse: canUseCache,
                    canSaveResponseToCache: canSaveCache,
                    canUseOldCachedResponseAsFallback: fallbackToStaleCache,
                    maxCacheAge: maxCacheAge
                )
                cachedCurrentUser = user
                return user
            } catch {
                print("Error retrieving current user: \(error)")
                return nil
            }
        }
        
        currentUserLock = task
        return try await task.value
    }
    
    public func discardCurrentUserCache() {
        cachedCurrentUser = nil
        Task {
            try? await _cacheEngine?.removeCacheEntry(key: currentUserCacheKey)
        }
    }
    
    /// Sends a password request to the server for the provided [email].
    /// Your server must have email sending configured. It will send an email (from the template located at `/extensions/templates/password-reset.liquid`) to the user with a link to page to finalize his password reset.
    /// Your directus server already has a web page where the user will be sent to choose and save a new password.
    ///
    /// You can provide an optional [resetUrl] if you want to send the user to your own password reset web page.
    /// If you do, you have to add the url the `PASSWORD_RESET_URL_ALLOW_LIST` environment variable for it to be accepted.
    /// That page will receive the reset token by parameter so you can call the password change api from there.
    public func requestPasswordReset(email: String, resetUrl: String?) async throws -> Bool {
        return try await _sendRequest(prepareRequest: {
            try _api.preparePasswordResetRequest(email: email, resetUrl: resetUrl)
        }, parseResponse: { response, data in
            try _api.parseGenericBoolResponse(data: data, response: response)
        }, canUseCacheForResponse: false)
    }
    
    /// Saves the new password chosen by the user after requesting a password reset using the [requestPasswordReset] function.
    ///
    /// Only use this API if you do not rely on directus standard password reset page.
    /// If you have your own custom password reset page, it will receive the refresh [token] as a GET parameter on load and the user will have to chose a [password] himself.
    public func confirmPasswordReset(token: String, password: String) async throws -> Bool {
        try await _sendRequest(
            prepareRequest: {
                try _api.preparePasswordChangeRequest(token: token, newPassword: password)
            },
            parseResponse: { response, data in
                try _api.parseGenericBoolResponse(data: data, response: response)
            },
            dependsOnToken: false,
            canUseCacheForResponse: false,
            canSaveResponseToCache: false,
            canUseOldCachedResponseAsFallback: false
        )
    }
    
    public func logoutDirectusUser() async throws -> Bool {
        guard let request = try _api.prepareLogoutRequest() else {
            discardCurrentUserCache()
            return true
        }
        
        do {
            let result: Bool = try await _sendRequest(
                prepareRequest: { request },
                parseResponse: { response, data in
                    try _api.parseLogoutResponse(data: data, response: response)
                },
                dependsOnToken: false,
                canUseCacheForResponse: false,
                canUseOldCachedResponseAsFallback: false
            )
            discardCurrentUserCache()
            if result {
                KeychainStorage.deleteRefreshToken()
            }
            return result
        } catch {
            discardCurrentUserCache()
            return true
        }
    }
    
    private func _collectionMetadata<T>(for type: T.Type) -> CollectionMetadata where T : DirectusCollection {
        guard let metadata = CollectionMetadataRegistry.metadata(for: type) else {
            fatalError("No CollectionMetadata registered for \(type)")
        }
        return metadata
    }
    
    public func findListOfItems<T>(
        filter: Filter? = nil,
        sortBy: [SortProperty]? = nil,
        fields: String? = nil,
        limit: Int? = nil,
        offset: Int? = nil,
        requestIdentifier: String? = nil,
        canUseCache: Bool = false,
        canSaveCache: Bool = true,
        fallbackToStaleCache: Bool = true,
        maxCacheAge: TimeInterval = 86400
    ) async throws -> [T] where T : DirectusData, T : DirectusCollection {
        let metadata = _collectionMetadata(for: T.self)
        return try await _sendRequest(
            prepareRequest: {
                _api.prepareGetListOfItemsRequest(
                    endpointName: metadata.endpointName,
                    endpointPrefix: metadata.endpointPrefix,
                    fields: fields ?? metadata.defaultFields,
                    filter: filter,
                    sortBy: sortBy,
                    limit: limit,
                    offset: offset
                )
            },
            parseResponse: { response, data in
                let jsonList = try _api.parseGetListOfItemsResponse(data: data, response: response)
                return try jsonList.map {
                    guard let object = $0 as? [String: Any] else {
                        throw URLError(.cannotParseResponse)
                    }
                    return try T(object)
                }
            },
            requestIdentifier: requestIdentifier,
            canUseCacheForResponse: canUseCache,
            canSaveResponseToCache: canSaveCache,
            canUseOldCachedResponseAsFallback: fallbackToStaleCache,
            maxCacheAge: maxCacheAge
        )
    }
    
    public func findListOfItemsWithResult<T>(
        filter: (any Filter)?,
        sortBy: [SortProperty]?,
        fields: String?,
        limit: Int?,
        offset: Int?,
        requestIdentifier: String? = nil,
        canUseCache: Bool = false,
        canSaveCache: Bool = true,
        fallbackToStaleCache: Bool = true,
        maxCacheAge: TimeInterval = 86400
    ) async -> Result<[T], any Error> where T : DirectusData, T : DirectusCollection {
        do {
            let metadata = _collectionMetadata(for: T.self)
            
            let items = try await _sendRequest(
                prepareRequest: {
                    _api.prepareGetListOfItemsRequest(
                        endpointName: metadata.endpointName,
                        endpointPrefix: metadata.endpointPrefix,
                        fields: fields ?? metadata.defaultFields,
                        filter: filter,
                        sortBy: sortBy,
                        limit: limit,
                        offset: offset
                    )
                },
                parseResponse: { response, data in
                    let jsonList = try _api.parseGetListOfItemsResponse(data: data, response: response)
                    return try jsonList.map {
                        guard let object = $0 as? [String: Any] else {
                            throw URLError(.cannotParseResponse)
                        }
                        return try T(object)
                    }
                },
                requestIdentifier: requestIdentifier,
                canUseCacheForResponse: canUseCache,
                canSaveResponseToCache: canSaveCache,
                canUseOldCachedResponseAsFallback: fallbackToStaleCache,
                maxCacheAge: maxCacheAge
            )
            
            return .success(items)
        } catch {
            return .failure(error)
        }
    }
    
    public func getSpecificItem<T>(
        id: String,
        fields: String?,
        requestIdentifier: String? = nil,
        canUseCache: Bool = false,
        canSaveCache: Bool = true,
        fallbackToStaleCache: Bool = true,
        maxCacheAge: TimeInterval = 86400
    ) async throws -> T? where T : DirectusData, T : DirectusCollection {
        let metadata = _collectionMetadata(for: T.self)
        let cacheKey = requestIdentifier ?? "\(metadata.endpointName)/\(id)"
        
        return try await _sendRequest(
            prepareRequest: {
                _api.prepareGetSpecificItemRequest(
                    fields: fields ?? metadata.defaultFields,
                    endpointPrefix: metadata.endpointPrefix,
                    endpointName: metadata.endpointName,
                    itemId: id,
                    tags: [cacheKey]
                )
            },
            parseResponse: { response, data in
                do {
                    let json = try _api.parseGetSpecificItemResponse(data: data, response: response)
                    guard let dict = json as? [String: Any] else {
                        throw URLError(.cannotParseResponse)
                    }
                    return try T(dict)
                } catch {
                    print("Error parsing response: \(error)")
                    return nil
                }
            },
            dependsOnToken: true,
            requestIdentifier: cacheKey,
            canUseCacheForResponse: canUseCache,
            canSaveResponseToCache: canSaveCache,
            canUseOldCachedResponseAsFallback: fallbackToStaleCache,
            maxCacheAge: maxCacheAge
        )
    }
    
    public func createNewItem<T>(objectToCreate: T, fields: String?) async throws -> DirectusItemCreationResult<T> where T : DirectusData, T : DirectusCollection {
        let metadata = _collectionMetadata(for: T.self)
        
        return try await _sendRequest(
            prepareRequest: {
                let payload = objectToCreate.mapForObjectCreation()
                
                return _api.prepareCreateNewItemRequest(
                    endpointName: metadata.endpointName,
                    endpointPrefix: metadata.endpointPrefix,
                    objectData: payload,
                    fields: fields ?? metadata.defaultFields
                )
            },
            parseResponse: { response, data in
                let parsedData = try _api.parseCreateNewItemResponse(data: data, response: response)
                
                guard parsedData is [String: Any] else {
                    throw URLError(.cannotParseResponse)
                }
                
                return DirectusItemCreationResult
                    .fromDirectus(api: _api,
                                  response: response,
                                  data: data,
                                  constructor: { dict in
                        try T(dict)
                    })
            },
            dependsOnToken: true,
            requestIdentifier: nil,
            canUseCacheForResponse: false,
            canSaveResponseToCache: false,
            canUseOldCachedResponseAsFallback: false,
            maxCacheAge: 0
        )
    }
    
    public func createMultipleItems<T>(objectList: [T], fields: String?) async throws -> DirectusItemCreationResult<T> where T : DirectusData, T : DirectusCollection {
        guard !objectList.isEmpty else {
            throw DirectusApiError(
                response: nil,
                bodyData: nil,
                customMessage: "objectList must not be empty"
            )
        }
        
        let metadata = _collectionMetadata(for: T.self)
        let mappedList: [[String: Any]] = objectList.map { $0.mapForObjectCreation() }
        
        return try await _sendRequest(
            prepareRequest: {
                _api.prepareCreateNewItemRequest(
                    endpointName: metadata.endpointName,
                    endpointPrefix: metadata.endpointPrefix,
                    objectData: mappedList,
                    fields: fields ?? metadata.defaultFields
                )
            },
            parseResponse: { response, data in
                switch response.statusCode {
                case 200:
                    var result: [T] = []
                    let parsedList = try _api.parseCreateNewItemResponse(
                        data: data,
                        response: response
                    )
                    if let list = parsedList as? [[String: Any]] {
                        for itemData in list {
                            let object = try T(itemData)
                            result.append(object)
                        }
                    } else if let single = parsedList as? [String: Any] {
                        let object = try T(single)
                        result.append(object)
                    }
                    return DirectusItemCreationResult<T>.success(result)
                case 204:
                    return DirectusItemCreationResult.success([])
                default:
                    throw DirectusApiError(
                        response: response,
                        bodyData: data,
                        customMessage: nil
                    )
                }
            },
            dependsOnToken: true,
            requestIdentifier: nil,
            canUseCacheForResponse: false,
            canSaveResponseToCache: false,
            canUseOldCachedResponseAsFallback: false,
            maxCacheAge: 0
        )
    }
    
    /// Update the item with the given [objectToUpdate]. You have to specify a Type which extends DirectusData.
    ///
    /// By default it will return an object of the same type as the one you provided with the default fields you specified in the [CollectionMetadata] annotation. You change the fields by providing a [fields] parameter.
    ///
    /// If [force] is true, the update will be done even if the object does not need saving,
    /// otherwise it will only send the modified data for this object.
    public func updateItem<T>(objectToUpdate: T, fields: String?, force: Bool = false) async throws -> T where T : DirectusData, T : DirectusCollection {
        
        let metadata = _collectionMetadata(for: T.self)
        let id = objectToUpdate.id
        guard let id else {
            throw DirectusApiError(
                response: nil, bodyData: nil, customMessage: "Missing ID for update"
            )
        }
        
        var updatedObject: T = objectToUpdate
        
        if objectToUpdate.needsSaving || force {
            var dataToUpdate: [String: Any] = force
            ? objectToUpdate.getRawData()
            : objectToUpdate.updatedProperties
            
            // Filter fields according to defaultUpdateFields if provided
            if let allowedFields = metadata.defaultUpdateFields,
               allowedFields != "*" {
                let allowedSet = Set(allowedFields.components(separatedBy: ","))
                dataToUpdate = dataToUpdate.filter { key, _ in
                    key == "id" || allowedSet.contains(key)
                }
            }
            
            //            // Send update request
            //            let updatedData: [String: Any] = try await _sendRequest(
            
            // Send update request and get the updated object directly
            let newObject: T = try await _sendRequest(
                prepareRequest: {
                    _api.prepareUpdateItemRequest(
                        endpointName: metadata.endpointName,
                        endpointPrefix: metadata.endpointPrefix,
                        itemId: id,
                        objectData: dataToUpdate,
                        fields: fields ?? metadata.defaultUpdateFields ?? metadata.defaultFields
                    )
                },
                parseResponse: { response, data in
                    guard let parsed = try _api.parseUpdateItemResponse(data: data, response: response) as? [String: Any] else {
                        throw URLError(.cannotParseResponse)
                    }
                    //                    return parsed
                    let fullData = objectToUpdate.getRawData().merging(parsed, uniquingKeysWith: { _, new in new })
                    return try T(fullData)
                },
                dependsOnToken: true,
                requestIdentifier: nil,
                canUseCacheForResponse: false,
                canSaveResponseToCache: false,
                canUseOldCachedResponseAsFallback: false,
                maxCacheAge: 0
            )
            
            //            let fullData = objectToUpdate.getRawData().merging(updatedData as [String : Any], uniquingKeysWith: { _, new in new })
            //            updatedObject = try T(fullData)
            
            updatedObject = newObject
            
            // Optional: clear cache for this item
            try? await _cacheEngine?.removeCacheEntriesWithTag(tag: "\(metadata.endpointName)/\(id)")
        }
        
        return updatedObject
    }
    
    public func deleteItem<T>(objectId: String, ofType type: T.Type, mustBeAuthenticated: Bool = true) async throws -> Bool where T : DirectusData, T : DirectusCollection {
        let metadata = _collectionMetadata(for: T.self)
        do {
            let wasDeleted = try await _sendRequest(
                prepareRequest: {
                    _api.prepareDeleteItemRequest(
                        endpointPrefix: metadata.endpointPrefix,
                        endpointName: metadata.endpointName,
                        itemId: objectId,
                        mustBeAuthenticated: mustBeAuthenticated
                    )
                },
                parseResponse: { response, data in
                    try _api.parseGenericBoolResponse(data: data, response: response)
                },
                dependsOnToken: true,
                requestIdentifier: nil,
                canUseCacheForResponse: false,
                canSaveResponseToCache: false,
                canUseOldCachedResponseAsFallback: false,
                maxCacheAge: 0
            )
            
            try? await _cacheEngine?.removeCacheEntriesWithTag(
                tag: "\(metadata.endpointName)/\(objectId)"
            )
            
            return wasDeleted
        } catch {
            return false
        }
    }
    
    public func deleteMultipleItems<T>(objectIdsToDelete: [Any], ofType type: T.Type, mustBeAuthenticated: Bool = true) async throws -> Bool where T : DirectusData, T : DirectusCollection {
        guard !objectIdsToDelete.isEmpty else {
            throw DirectusApiError(
                response: nil, bodyData: nil, customMessage: "objectIdsToDelete cannot be empty"
            )
        }
        
        let metadata = _collectionMetadata(for: T.self)
        
        let wasDeleted = try await _sendRequest(
            prepareRequest: {
                _api.prepareDeleteMultipleItemRequest(
                    endpointName: metadata.endpointName,
                    endpointPrefix: metadata.endpointPrefix,
                    itemIdList: objectIdsToDelete,
                    mustBeAuthenticated: mustBeAuthenticated
                )
            },
            parseResponse: { response, data in
                try _api.parseGenericBoolResponse(data: data, response: response)
            },
            dependsOnToken: true,
            requestIdentifier: nil,
            canUseCacheForResponse: false,
            canSaveResponseToCache: false,
            canUseOldCachedResponseAsFallback: false,
            maxCacheAge: 0
        )
        
        if let cacheEngine = self._cacheEngine {
            for id in objectIdsToDelete {
                if let idString = id as? String {
                    try? await cacheEngine.removeCacheEntriesWithTag(tag: "\(metadata.endpointName)/\(idString)")
                }
            }
        }
        
        return wasDeleted
    }
    
    public func getFile(fileId: String) async throws -> Data {
        return try await _sendRequest(
            prepareRequest: {
                try _api.prepareFileDownloadRequest(fileId: fileId)
            },
            parseResponse: { response, data in
                try _api.parseFileDownloadResponse(data: data, response: response)
            },
            canSaveResponseToCache: true
        )
    }
    
    public func uploadFileFromUrl(remoteUrl: String, title: String?, folder: String?) async throws -> DirectusFile {
        return try await _sendRequest(
            prepareRequest: {
                try _api
                    .prepareFileImportRequest(
                        url: remoteUrl,
                        title: title,
                        folder: folder
                    )
            },
            parseResponse: { response, data in
                try _api.parseFileUploadResponse(data: data, response: response)
            },
            canSaveResponseToCache: false
        )
    }
    
    public func uploadFile(fileBytes: [UInt8], filename: String, title: String?, contentType: String?, folder: String?, storage: String = "local") async throws -> DirectusFile {
        return try await _sendRequest(
            prepareRequest: {
                try _api
                    .prepareNewFileUploadRequest(
                        fileBytes: fileBytes,
                        title: title,
                        contentType: contentType,
                        filename: filename,
                        folder: folder,
                        storage: storage
                    )
            },
            parseResponse: { response, data in
                try _api.parseFileUploadResponse(data: data, response: response)
            },
            canSaveResponseToCache: false
        )
    }
    
    public func updateExistingFile(fileBytes: [UInt8], fileId: String, filename: String, contentType: String?) async throws -> DirectusFile {
        return try await _sendRequest(
            prepareRequest: {
                try _api
                    .prepareUpdateFileRequest(
                        fileId: fileId,
                        fileBytes: fileBytes,
                        title: nil,
                        contentType: contentType,
                        filename: filename
                    )
            },
            parseResponse: { response, data in
                try _api.parseFileUploadResponse(data: data, response: response)
            },
            canSaveResponseToCache: false
        )
    }
    
    public func deleteFile(fileId: String) async throws -> Bool {
        return try await _sendRequest(
            prepareRequest: {
                try _api.prepareFileDeleteRequest(fileId: fileId)
            },
            parseResponse: { response, data in
                try _api
                    .parseGenericBoolResponse(data: data, response: response)
            },
            canSaveResponseToCache: false
        )
    }
    
    public func sendRequestToEndpoint<T: Sendable>(
        prepareRequest: () -> URLRequest,
        jsonConverter: @escaping (HTTPURLResponse, Data) throws -> T,
        requestIdentifier: String? = nil,
        canUseCacheForResponse: Bool = false,
        canSaveResponseToCache: Bool = true,
        canUseOldCachedResponseAsFallback: Bool = true,
        maxCacheAge: TimeInterval = 86400
    ) async throws -> T {
        return try await _sendRequest(
            prepareRequest: {
                let request = prepareRequest()
                return PreparedRequest(request: request, tags: ["customRequest"])
            },
            parseResponse: { response, data in
                try jsonConverter(response, data)
            },
            dependsOnToken: true,
            requestIdentifier: requestIdentifier,
            canUseCacheForResponse: canUseCacheForResponse,
            canSaveResponseToCache: canSaveResponseToCache,
            canUseOldCachedResponseAsFallback: canUseOldCachedResponseAsFallback,
            maxCacheAge: maxCacheAge
        )
    }
    
    public func registerDirectusUser(email: String, password: String, firstname: String?, lastname: String?) async throws -> Bool {
        throw DirectusApiError(response: nil, bodyData: nil , customMessage: "Not implemented yet")
    }
}
