//
//  PreparedRequest.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

public struct PreparedRequest: @unchecked Sendable {
    public let request: Any
    public let tags: [String]

    public init(request: Any, tags: [String] = []) {
        self.request = request
        self.tags = tags
    }
}
