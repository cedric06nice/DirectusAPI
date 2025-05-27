//
//  MultipartRequest.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

public struct MultipartRequest: Codable {
    public var method: String
    public var url: String?
    public var files: [MultipartFile]
    public var fields: [String: String]

    public init(method: String, files: [MultipartFile], fields: [String: String] = [:]) {
        self.method = method
        self.files = files
        self.fields = fields
    }
}

public struct MultipartFile: Codable {
    public var filename: String
    public var contentType: ContentType

    public init(filename: String, contentType: ContentType) {
        self.filename = filename
        self.contentType = contentType
    }
}

public struct ContentType: Codable {
    public var mimeType: String
}
