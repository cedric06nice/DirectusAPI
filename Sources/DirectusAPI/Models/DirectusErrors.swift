//
//  DirectusErrors.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

@MainActor
enum DirectusErrorCode: String, Codable, Sendable {
    case invalidPayload = "INVALID_PAYLOAD"
    case invalidCredentials = "INVALID_CREDENTIALS"
    case invalidOTP = "INVALID_OTP"
}

// MARK: - DirectusError
@MainActor
struct DirectusError: Codable, Sendable {
    let reason: String?
    let code: DirectusErrorCode
    
    enum CodingKeys: String, CodingKey {
        case reason = "reason"
        case code = "code"
    }
}

// MARK: Extensions convenience initializers and mutators
extension DirectusError {
    init(data: Data) throws {
        self = try JSONDecoder().decode(DirectusError.self, from: data)
    }
    
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        reason: String? = nil,
        code: DirectusErrorCode? = nil
    ) -> DirectusError {
        return DirectusError(
            reason: reason ?? self.reason,
            code: code ?? self.code
        )
    }
    
    func jsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - DirectusErrorExtension
@MainActor
struct DirectusErrorExtension: Codable, Sendable {
    let message: String
    let extensions: DirectusError
    
    enum CodingKeys: String, CodingKey {
        case message = "message"
        case extensions = "extensions"
    }
}

// MARK: Error convenience initializers and mutators
extension DirectusErrorExtension {
    init(data: Data) throws {
        self = try JSONDecoder().decode(DirectusErrorExtension.self, from: data)
    }
    
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        message: String? = nil,
        extensions: DirectusError? = nil
    ) -> DirectusErrorExtension {
        return DirectusErrorExtension(
            message: message ?? self.message,
            extensions: extensions ?? self.extensions
        )
    }
    
    func jsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - DirectusErrors
@MainActor
struct DirectusErrors: Error, Codable, Sendable {
    let errors: [DirectusErrorExtension]
    
    enum CodingKeys: String, CodingKey {
        case errors = "errors"
    }
    
    var description: String {
        var errorString: String = ""
        for error in self.errors {
            switch error.extensions.code {
            case .invalidPayload:
                errorString = "\(error.extensions.reason ?? "No reason given.") "
            case .invalidCredentials:
                errorString = "\(error.message) "
            case .invalidOTP:
                errorString = "\(error.extensions.reason ?? "No reason given.")"
            }
        }
        return errorString
    }
}

// MARK: DirectusErrors convenience initializers and mutators
extension DirectusErrors {
    init(data: Data) throws {
        self = try JSONDecoder().decode(DirectusErrors.self, from: data)
    }
    
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        errors: [DirectusErrorExtension]? = nil
    ) -> DirectusErrors {
        return DirectusErrors(
            errors: errors ?? self.errors
        )
    }
    
    func jsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
