//
//  DirectusItemCreationResult.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

@MainActor
public enum DirectusItemCreationResult<T> {
    case success([T])
    case failure(DirectusApiError)
    
    var createdItemList: [T]? {
        if case let .success(items) = self {
            return items
        }
        return nil
    }

    var createdItem: T? {
        if case let .success(items) = self {
            return items.first
        }
        return nil
    }

    static func fromDirectus(
        api: DirectusAPIProtocol,
        response: HTTPURLResponse,
        data: Data,
        constructor: ([String: Any]) throws -> T
    ) -> DirectusItemCreationResult<T> {
        guard response.statusCode == 200 || response.statusCode == 204 else {
            return .failure(DirectusApiError(response: response, bodyData: data, customMessage: nil))
        }
        
        guard response.statusCode == 200 else {
            return .success([])
        }
        
        guard let objectData = try? api.parseCreateNewItemResponse(data: data, response: response),
              let objectDict = objectData as? [String: Any],
              let item = try? constructor(objectDict) else {
            return .failure(DirectusApiError(response: response, bodyData: data, customMessage: "Parse Error"))
        }
            return .success([item])
    }
}
