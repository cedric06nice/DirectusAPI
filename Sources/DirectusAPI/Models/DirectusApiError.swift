//
//  DirectusApiError.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

public struct DirectusApiError: Error, LocalizedError {
    let response: HTTPURLResponse?
    let bodyData: Data?
    let customMessage: String?

    public var errorDescription: String? {
        guard let data = bodyData else {
            return "DirectusApiError: \(customMessage ?? "No custom message")"
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errors = json["errors"] as? [[String: Any]] {
                let messages = errors.compactMap { $0["message"] as? String }.joined(separator: ", ")
                return messages
            } else {
                return "DirectusApiError: Unexpected JSON format. Response: \(String(data: data, encoding: .utf8) ?? "")"
            }
        } catch {
            return "DirectusApiError: Failed to parse error. Body: \(String(data: data, encoding: .utf8) ?? "")"
        }
    }
}
