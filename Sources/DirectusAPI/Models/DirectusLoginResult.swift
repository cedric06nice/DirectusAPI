//
//  DirectusLoginResult.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

@MainActor
public enum DirectusLoginResultType: String, Codable {
    case success
    case invalidCredentials
    case invalidOTP
    case error
}

@MainActor
public struct DirectusLoginResult {
    public let type: DirectusLoginResultType
    public let message: String?
    
    init(type: DirectusLoginResultType, message: String? = nil) {
        self.type = type
        self.message = message
    }
    
    static let success = DirectusLoginResult(type: .success)
}
