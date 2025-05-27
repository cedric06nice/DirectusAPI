//
//  DirectusUser.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

@MainActor
public enum DirectusUserStatus: String, Codable {
    case draft, invited, unverified, active, suspended, archived
}

@MainActor
public final class DirectusUser: DirectusData {
    public internal(set) var email: String? {
        get { getValue(forKey: "email") as? String }
        set { setValue(newValue, forKey: "email") }
    }
    
    public internal(set) var password: String? {
        get { getValue(forKey: "password") as? String }
        set { setValue(newValue, forKey: "password") }
    }
    
    public internal(set) var firstname: String? {
        get { getValue(forKey: "first_name") as? String }
        set { setValue(newValue, forKey: "first_name") }
    }
    
    public internal(set) var lastname: String? {
        get { getValue(forKey: "last_name") as? String }
        set { setValue(newValue, forKey: "last_name") }
    }
    
    public internal(set) var descriptionText: String? {
        get { getValue(forKey: "description") as? String }
        set { setValue(newValue, forKey: "description") }
    }
    
    public internal(set) var roleUUID: String? {
        get { getValue(forKey: "role") as? String }
        set { setValue(newValue, forKey: "role") }
    }
    
    public internal(set) var avatar: String? {
        get { getValue(forKey: "avatar") as? String }
        set { setValue(newValue, forKey: "avatar") }
    }
    
    public internal(set) var status: DirectusUserStatus? {
        get {
            guard let raw = getValue(forKey: "status") as? String else { return nil }
            return DirectusUserStatus(rawValue: raw)
        }
        set {
            setValue(newValue?.rawValue, forKey: "status")
        }
    }
    
    public var fullName: String {
        let first = firstname ?? ""
        let last = lastname ?? ""
        return first.isEmpty ? last : last.isEmpty ? first : "\(first) \(last)"
    }
    
    required init(_ data: [String: Any]) throws {
        try super.init(data)
    }
    
    static func newUser(
        email: String,
        password: String,
        firstname: String? = nil,
        lastname: String? = nil,
        roleUUID: String? = nil,
        otherProperties: [String: Any] = [:]
    ) -> DirectusUser {
        var data: [String: Any] = [
            "id": UUID().uuidString,
            "email": email,
            "password": password
        ]
        data["first_name"] = firstname
        data["last_name"] = lastname
        data["role"] = roleUUID
        otherProperties.forEach { data[$0.key] = $0.value }
        
        return try! DirectusUser(data)
    }
}

extension DirectusUser: @preconcurrency Codable {
    enum CodingKeys: String, CodingKey {
        case id, email, password
        case firstname = "first_name"
        case lastname = "last_name"
        case descriptionText = "description"
        case roleUUID = "role"
        case avatar
        case status
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var dict: [String: Any] = [:]
        
        if let id = try container.decodeIfPresent(String.self, forKey: .id) {
            dict["id"] = id
        }
        dict["email"] = try container.decodeIfPresent(String.self, forKey: .email)
        dict["password"] = try container.decodeIfPresent(String.self, forKey: .password)
        dict["first_name"] = try container.decodeIfPresent(String.self, forKey: .firstname)
        dict["last_name"] = try container.decodeIfPresent(String.self, forKey: .lastname)
        dict["description"] = try container.decodeIfPresent(String.self, forKey: .descriptionText)
        dict["role"] = try container.decodeIfPresent(String.self, forKey: .roleUUID)
        dict["avatar"] = try container.decodeIfPresent(String.self, forKey: .avatar)
        dict["status"] = try container.decodeIfPresent(String.self, forKey: .status)
        
        try self.init(dict)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(password, forKey: .password)
        try container.encodeIfPresent(firstname, forKey: .firstname)
        try container.encodeIfPresent(lastname, forKey: .lastname)
        try container.encodeIfPresent(descriptionText, forKey: .descriptionText)
        try container.encodeIfPresent(roleUUID, forKey: .roleUUID)
        try container.encodeIfPresent(avatar, forKey: .avatar)
        try container.encodeIfPresent(status?.rawValue, forKey: .status)
    }
}
