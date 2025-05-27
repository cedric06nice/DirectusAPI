// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

@MainActor
@Observable
internal final class DirectusAPI: DirectusAPIProtocol {
    
    internal var _baseURL: String
    
    internal var _accessToken: String?
    internal var _refreshToken: String?
    
    internal var _accessTokenExpiration: Date?
    internal let _saveRefreshToken: ((String) async -> Void)?
    internal let _loadRefreshToken: (() async -> String?)?
    
    public init(
        baseURL: String,
        saveRefreshToken: ((String) async -> Void)? = nil,
        loadRefreshToken: (() async -> String?)? = nil
    ) {
        self._baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        self._saveRefreshToken = saveRefreshToken
        self._loadRefreshToken = loadRefreshToken
    }
    
    var baseURL: String { _baseURL }
    var accessToken: String? { _accessToken }
    var refreshToken: String? {
        get { _refreshToken }
        set { _refreshToken = newValue }
    }
    
    var hasLoggedInUser: Bool {
        return accessToken != nil && refreshToken != nil
    }
    
    var shouldRefreshToken: Bool {
        if (_refreshToken != nil || _loadRefreshToken != nil) {
            if _accessToken == nil {
                return true
            }
            guard let expiration = _accessTokenExpiration else {
                return false
            }
            return expiration < Date()
        }
        return false
    }
    
    var currentAuthToken: String?
    
    // MARK: - Authentication
    
    func authenticateRequest(_ request: inout URLRequest) -> URLRequest {
        if let accessToken = _accessToken {
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
    
    // MARK: - Login
    
    func prepareLoginRequest(username email: String, password: String, oneTimePassword otp: String? = nil) throws -> PreparedRequest {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        var body: [String: Any] = ["email": email, "password": password]
        if let otp {
            body["otp"] = otp
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.addJsonHeaders()
        return PreparedRequest(request: request)
    }
    
    func parseLoginResponse(data: Data, response: HTTPURLResponse) async -> DirectusLoginResult {
        _accessToken = nil
        _refreshToken = nil
        
        if response.statusCode != 200 {
            if response.statusCode == 401 {
                do {
                    let json = try JSONDecoder().decode(
                        DirectusErrors.self,
                        from: data
                    )
                    guard let errorCode: DirectusErrorCode = json.errors.first?.extensions.code else {
                        return DirectusLoginResult(
                            type: .error,
                            message: "Missing data field."
                        )
                    }
                    if errorCode == .invalidOTP {
                        return DirectusLoginResult(
                            type: .invalidOTP,
                            message: _extractErrorMessageFromResponse(from: data)
                        )
                    } else if errorCode == .invalidCredentials {
                        return DirectusLoginResult(
                            type: .invalidCredentials,
                            message: _extractErrorMessageFromResponse(from: data)
                        )
                    } else {
                        return DirectusLoginResult(
                            type: .error,
                            message: _extractErrorMessageFromResponse(from: data)
                        )
                    }
                } catch {
                    return DirectusLoginResult(
                        type: .error,
                        message: _extractErrorMessageFromResponse(from: data)
                    )
                }
            }
        }
        
        guard response.statusCode == 200 else {
            return DirectusLoginResult(
                type: .error,
                message: _extractErrorMessageFromResponse(from: data)
            )
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let data = json?["data"] as? [String: Any] else {
                return DirectusLoginResult(
                    type: .error,
                    message: _extractErrorMessageFromResponse(from: data)
                )
            }
            
            _accessToken = data["access_token"] as? String
            let newRefreshToken = data["refresh_token"] as? String
            _refreshToken = newRefreshToken
            if let token = newRefreshToken {
                await _saveRefreshToken?(token)
            }
            
            if let expires = data["expires"] as? Int {
                _accessTokenExpiration = Date().addingTimeInterval(TimeInterval(expires / 1000))
            }
            
            if _accessToken != nil && _refreshToken != nil {
                return DirectusLoginResult(type: .success)
            } else {
                return DirectusLoginResult(type: .error, message: "Incomplete token response.")
            }
        } catch {
            return DirectusLoginResult(
                type: .error,
                message: _extractErrorMessageFromResponse(from: data)
            )
        }
    }
    
    // MARK: - Token
    func prepareRefreshTokenRequest() async throws -> PreparedRequest {
        if self._refreshToken == nil {
            if let loadToken = self._loadRefreshToken {
                self._refreshToken = await loadToken()
            }
        }
        let request = try _prepareStokedRefreshTokenRequest()
        return PreparedRequest(request: request)
    }
    
    private func _prepareStokedRefreshTokenRequest() throws -> URLRequest {
        // Ensure we have a valid refresh token
        guard let token = _refreshToken, !token.isEmpty else {
            throw URLError(.userAuthenticationRequired, userInfo: [
                NSLocalizedDescriptionKey: "Missing refresh token"
            ])
        }
        
        // Build the URLRequest
        var request = URLRequest(url: URL(string: "\(_baseURL)/auth/refresh")!)
        request.httpMethod = "POST"
        request.addJsonHeaders()
        let body: [String: String] = ["refresh_token": token]
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }
    
    func parseRefreshTokenResponse(data: Data, response: HTTPURLResponse) async throws -> Bool {
        let responseParsingResult = await parseLoginResponse(
            data: data,
            response: response
        )
        return responseParsingResult.type == .success
    }
    
    // MARK: - Logout
    
    func prepareLogoutRequest() throws -> PreparedRequest? {
        do {
            let tokenRefreshRequest = try _prepareStokedRefreshTokenRequest()
            var logoutRequest = URLRequest(url: URL(string: "\(_baseURL)/auth/logout")!)
            logoutRequest.httpMethod = "POST"
            logoutRequest.addJsonHeaders()
            logoutRequest.httpBody = tokenRefreshRequest.httpBody
            return PreparedRequest(request: logoutRequest)
        } catch {
            return nil
        }
    }
    
    func parseLogoutResponse(data: Data, response: HTTPURLResponse) throws -> Bool {
        if (response.statusCode < 200 || response.statusCode > 299) {
            return false
        }
        _refreshToken = nil
        _accessToken = nil
        _accessTokenExpiration = nil
        return true
    }
    
    // MARK: - Current User
    
    func prepareGetCurrentUserRequest(fields: String = "*") -> PreparedRequest {
        return prepareGetSpecificItemRequest(
            fields: fields,
            endpointPrefix: "/",
            endpointName: "users",
            itemId: "me"
        )
    }
    
    // MARK: - Items GET
    
    func parseGetListOfItemsResponse(data: Data, response: HTTPURLResponse) throws -> [Any] {
        return try _parseGenericResponse(data: data, response: response) as? [Any] ?? []
        //        if response.statusCode == 200 {
        //            return try _parseGenericResponse(data: data, response: response) as! [Any]
        //        } else {
        //            if let errorMessage = _extractErrorMessageFromResponse(from: data) {
        //                return [errorMessage]
        //            }
        //            return []
        //        }
    }
    
    func prepareGetListOfItemsRequest(endpointName: String, endpointPrefix: String, fields: String = "*", filter: Filter? = nil, sortBy: [SortProperty]? = nil, limit: Int? = nil, offset: Int? = nil) -> PreparedRequest {
        let request = _prepareGetRequest(
            path: "\(endpointPrefix)\(endpointName)",
            fields: fields,
            filter: filter,
            sortBy: sortBy,
            limit: limit,
            offset: offset
        )
        return request
    }
    
    func parseGetSpecificItemResponse(data: Data, response: HTTPURLResponse) throws -> Any {
        return try _parseGenericResponse(data: data, response: response)
    }
    
    func prepareGetSpecificItemRequest(fields: String = "*", endpointPrefix: String, endpointName: String, itemId: String, tags: [String] = []) -> PreparedRequest {
        return _prepareGetRequest(
            path: "\(endpointPrefix)\(endpointName)/\(itemId)",
            fields: fields
        )
    }
    
    // MARK: - Items CREATE
    
    func prepareCreateNewItemRequest(endpointName: String, endpointPrefix: String, objectData: Any, fields: String = "*") -> PreparedRequest {
        let url = URL(string: "\(_baseURL)\(endpointPrefix)\(endpointName)?fields=\(fields)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addJsonHeaders()
        request.httpBody = try? JSONSerialization.data(withJSONObject: objectData, options: [])
        return PreparedRequest(request: authenticateRequest(&request))
    }
    
    func parseCreateNewItemResponse(data: Data, response: HTTPURLResponse) throws -> Any {
        return try parseGetSpecificItemResponse(data: data, response: response)
    }
    
    // MARK: - Items UPDATE
    
    func prepareUpdateItemRequest(endpointName: String, endpointPrefix: String, itemId: String, objectData: Any, fields: String = "*") -> PreparedRequest {
        let url = URL(
            string: "\(_baseURL)\(endpointPrefix)\(endpointName)/\(itemId)?fields=\(fields)"
        )!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addJsonHeaders()
        request.httpBody = try? JSONSerialization.data(withJSONObject: objectData, options: [])
        return PreparedRequest(request: authenticateRequest(&request))
    }
    
    func parseUpdateItemResponse(data: Data, response: HTTPURLResponse) throws -> Any {
        return try parseGetSpecificItemResponse(data: data, response: response)
    }
    
    // MARK: - Items DELETE
    
    func prepareDeleteItemRequest(endpointPrefix: String, endpointName: String, itemId: String, mustBeAuthenticated: Bool = false) -> PreparedRequest {
        let url = URL(
            string: "\(_baseURL)\(endpointPrefix)\(endpointName)/\(itemId)"
        )!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if mustBeAuthenticated {
            return PreparedRequest(request: authenticateRequest(&request))
        }
        return PreparedRequest(request: request)
    }
    
    func prepareDeleteMultipleItemRequest(endpointName: String, endpointPrefix: String, itemIdList: [Any], mustBeAuthenticated: Bool) -> PreparedRequest {
        let url = URL(
            string: "\(_baseURL)\(endpointPrefix)\(endpointName)"
        )!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addJsonHeaders()
        request.httpBody = try? JSONSerialization
            .data(withJSONObject: itemIdList, options: [])
        if mustBeAuthenticated {
            return PreparedRequest(request: authenticateRequest(&request))
        }
        return PreparedRequest(request: request)
    }
    
    
    // MARK: - User Invite
    
    func prepareUserInviteRequest(email: String, roleId: String) -> PreparedRequest {
        let url = URL(string: "\(baseURL)/users/invite")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addJsonHeaders()
        let body: [String: Any] = ["email": email, "role": roleId]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print(error)
        }
        return PreparedRequest(request: request)
    }
    
    func parseUserInviteResponse(data: Data, response: HTTPURLResponse) throws -> Bool {
        return response.statusCode == 200
    }
    
    //MARK: - Files
    
    func prepareFileDownloadRequest(fileId: String) throws -> PreparedRequest {
        let endpoint = URL(string: "\(_baseURL)/assets/\(fileId)")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.addJsonHeaders()
        return PreparedRequest(request: authenticateRequest(&request))
    }
    
    func prepareFileImportRequest(url: String, title: String? = nil, folder: String? = nil) -> PreparedRequest {
        let endpoint = URL(string: "\(_baseURL)/files/import")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addJsonHeaders()
        
        var payload: [String: Any] = [
            "url": url,
            "data": [
                "title": title as Any,
                "folder": folder as Any
            ]
        ]
        
        // Clean up nils from the nested dictionary
        if var data = payload["data"] as? [String: Any] {
            data = data.filter { $0.value is String }
            payload["data"] = data
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print(error)
        }
        
        return PreparedRequest(request: authenticateRequest(&request))
    }
    
    func prepareFileDeleteRequest(fileId: String) -> PreparedRequest {
        let endpoint = URL(string: "\(_baseURL)/files/\(fileId)")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "DELETE"
        return  PreparedRequest(request: authenticateRequest(&request))
    }
    
    func prepareNewFileUploadRequest(fileBytes: [UInt8], title: String? = nil, contentType: String? = nil, filename: String, folder: String? = nil, storage: String = "local") -> PreparedRequest {
        return PreparedRequest(
            request: _prepareMultipartFileRequest(
                method: "POST",
                url: "\(_baseURL)/files",
                fileBytes: fileBytes,
                title: title,
                contentType: contentType,
                filename: filename,
                folder: folder,
                storage: storage
            )
        )
    }
    
    func prepareUpdateFileRequest(fileId: String, fileBytes: [UInt8]? = nil, title: String? = nil, contentType: String? = nil, filename: String) throws -> PreparedRequest {
        return PreparedRequest(
            request: _prepareMultipartFileRequest(
                method: "PATCH",
                url: "\(_baseURL)/files/\(fileId)",
                fileBytes: fileBytes,
                title: title,
                contentType: contentType,
                filename: filename
            )
        )
    }
    
    func parseFileDownloadResponse(data: Data, response: HTTPURLResponse) throws -> Data {
        try _throwIfServerDeniedRequest(data: data, response: response)
        return data
    }
    
    func parseFileUploadResponse(data: Data, response: HTTPURLResponse) throws -> DirectusFile {
        try _throwIfServerDeniedRequest(data: data, response: response)
        let decoded = try JSONDecoder().decode(ResponseWrapper<DirectusFile>.self, from: data)
        return decoded.data
    }
    
    //MARK: - Password
    
    func preparePasswordResetRequest(email: String, resetUrl: String? = nil) throws -> PreparedRequest {
        let endpoint = URL(string: "\(_baseURL)/auth/password/request")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addJsonHeaders()
        
        var data = [String: String]()
        data["email"] = email
        if (resetUrl != nil) {
            data["reset_url"] = resetUrl
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: data)
        
        return PreparedRequest(request: request)
    }
    
    func preparePasswordChangeRequest(token: String, newPassword: String) throws -> PreparedRequest {
        let endpoint = URL(string: "\(_baseURL)/auth/password/reset")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addJsonHeaders()
        
        var data = [String: String]()
        data["token"] = token
        data["password"] = newPassword
        request.httpBody = try JSONSerialization.data(withJSONObject: data)
        
        return PreparedRequest(request: request)
    }
    
    //MARK: - Register User
    
    func prepareRegisterUserRequest(email: String, password: String, firstname: String? = nil, lastname: String? = nil) throws -> PreparedRequest {
        let endpoint = URL(string: "\(_baseURL)/users/register")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addJsonHeaders()
        
        var data = [String: String]()
        data["email"] = email
        data["password"] = password
        if (firstname != nil) {
            data["first_name"] = firstname
        }
        if (lastname != nil) {
            data["last_name"] = lastname
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: data)
        
        return  PreparedRequest(request: request)
    }
    
    
    //MARK: - Generic Bool
    
    func parseGenericBoolResponse(data: Data, response: HTTPURLResponse) throws -> Bool {
        try _throwIfServerDeniedRequest(data: data, response: response)
        return true
    }
    
    //MARK: - Private Methods
    
    private func _throwIfServerDeniedRequest(data: Data? = nil, response: HTTPURLResponse) throws {
        guard (200...299).contains(response.statusCode) else {
            if let data = data {
                throw NSError(
                    domain: "DirectusAPI",
                    code: response.statusCode,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Server denied this action. HTTP code: \(response.statusCode). \(_extractErrorMessageFromResponse(from: data) ?? "No error message in response")"
                    ]
                )
            } else {
                throw NSError(
                    domain: "DirectusAPI",
                    code: response.statusCode,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Server denied this action. HTTP code: \(response.statusCode)."
                    ]
                )
            }
        }
    }
    
    private func _parseGenericResponse(data: Data, response: HTTPURLResponse) throws -> Any {
        if response.statusCode != 200 {
            throw DirectusApiError(
                response: response,
                bodyData: data,
                customMessage: nil
            )
        }
        
        let decodedJson = try JSONSerialization.jsonObject(with: data) as! [String : Any]
        
        return decodedJson["data"] as Any
    }
    
    private func _prepareGetRequest(path: String, fields: String = "*", filter: Filter? = nil, sortBy: [SortProperty]? = nil, limit: Int? = nil, offset: Int? = nil) -> PreparedRequest {
        var components = URLComponents(string: _baseURL + path)!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "fields", value: fields)
        ]
        if let filter = filter {
            queryItems.append(URLQueryItem(name: "filter", value: filter.asJSON))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }
        if let sortBy = sortBy, !sortBy.isEmpty {
            let sortString = sortBy.map { $0.toString() }.joined(separator: ",")
            queryItems.append(URLQueryItem(name: "sort", value: sortString))
        }
        if let offset = offset {
            queryItems.append(URLQueryItem(name: "offset", value: "\(offset)"))
        }
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        
        return PreparedRequest(request: authenticateRequest(&request))
    }
    
    func _prepareMultipartFileRequest(
        method: String,
        url: String,
        fileBytes: [UInt8]? = nil,
        title: String? = nil,
        contentType: String? = nil,
        filename: String,
        folder: String? = nil,
        storage: String = "local"
    ) -> URLRequest {
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = method
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        func appendField(name: String, value: String) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        
        func appendFile(name: String, filename: String, contentType: String?, data: Data) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
            if let contentType = contentType {
                body.append("Content-Type: \(contentType)\r\n")
            }
            body.append("\r\n")
            body.append(data)
            body.append("\r\n")
        }
        
        appendField(name: "storage", value: storage)
        if let title { appendField(name: "title", value: title) }
        if let folder { appendField(name: "folder", value: folder) }
        
        if let fileBytes {
            appendFile(name: "file", filename: filename, contentType: contentType, data: Data(fileBytes))
        }
        
        body.append("--\(boundary)--\r\n")
        request.httpBody = body
        
        return authenticateRequest(&request)
    }
    
    func _extractErrorMessageFromResponse(from data: Data) -> String? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let errors = json["errors"] as? [[String: Any]],
            !errors.isEmpty
        else {
            return nil
        }
        
        return errors
            .compactMap { $0["message"] as? String }
            .joined(separator: "\n")
    }
    
    private func _toEncodable(_ value: Any) -> Any? {
        if let date = value as? Date {
            return ISO8601DateFormatter().string(from: date)
        }
        return nil
    }
    
    // MARK: - Utility
    
    public func convertPathToFullURL(path: String) -> String {
        if baseURL.hasSuffix("/") || path.hasPrefix("/") {
            return baseURL + path
        } else {
            return baseURL + "/" + path
        }
    }
    
    private struct ResponseWrapper<T: Decodable>: Decodable {
        let data: T
    }
}

@MainActor
public class SortProperty {
    let name: String
    let ascending: Bool
    
    init(name: String, ascending: Bool = true) {
        self.name = name
        self.ascending = ascending
    }
    
    func toString() -> String {
        return "\(ascending ? "" : "-")\(name)"
    }
}
