//
//  DirectusUserTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
import Foundation
@testable import DirectusAPI

@MainActor
struct DirectusUserTests {
    @Test("Full name is correctly concatenated")
    func testFullName() {
        let user = try! DirectusUser([
            "id": "user-123",
            "first_name": "Jane",
            "last_name": "Doe"
        ])
        #expect(user.fullName == "Jane Doe")
    }
    
    @Test("Email and role are correctly set")
    func testEmailAndRole() {
        let user = try! DirectusUser([
            "id": "user-123"
        ])
        user.email = "test@example.com"
        user.roleUUID = "role-456"
        
        #expect(user.email == "test@example.com")
        #expect(user.roleUUID == "role-456")
    }
    
    @Test("New user factory initializes properties correctly")
    func testNewUserFactory() {
        let user = DirectusUser.newUser(
            email: "new@user.com",
            password: "secret",
            firstname: "New",
            lastname: "User",
            roleUUID: "admin-role",
            otherProperties: ["avatar": "avatar-123"]
        )
        
        #expect(user.email == "new@user.com")
        #expect(user.firstname == "New")
        #expect(user.lastname == "User")
        #expect(user.roleUUID == "admin-role")
        #expect(user.avatar == "avatar-123")
    }
    
    @Test("Status can be assigned and retrieved")
    func testUserStatusAssignment() {
        let user = try! DirectusUser([
            "id": "user-789"
        ])
        
        user.status = .active
        #expect(user.status == .active)
        
        user.status = .suspended
        #expect(user.status == .suspended)
    }
    @Test("User encodes and decodes correctly with Codable")
    func testUserCodableRoundTrip() throws {
        let original = try DirectusUser([
            "id": "user-001",
            "email": "encoded@example.com",
            "first_name": "Code",
            "last_name": "Able",
            "role": "user-role",
            "status": "active"
        ])
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DirectusUser.self, from: data)
        
        #expect(decoded.id == original.id)
        #expect(decoded.email == original.email)
        #expect(decoded.firstname == original.firstname)
        #expect(decoded.lastname == original.lastname)
        #expect(decoded.roleUUID == original.roleUUID)
        #expect(decoded.status == original.status)
    }
    
    @Test("Modified fields persist in encoded output")
    func testUserEncodingPersistence() throws {
        let user = DirectusUser.newUser(
            email: "persist@example.com",
            password: "pass",
            firstname: "Persist",
            lastname: "Test"
        )
        user.status = .suspended
        user.avatar = "avatar-xyz"
        
        let data = try JSONEncoder().encode(user)
        let jsonString = String(data: data, encoding: .utf8)!
        
        #expect(jsonString.contains("\"email\":\"persist@example.com\""))
        #expect(jsonString.contains("\"status\":\"suspended\""))
        #expect(jsonString.contains("\"avatar\":\"avatar-xyz\""))
    }
    
    // MARK: - Edge Case Tests for DirectusUser
    
    @Test("Full name when only firstname or lastname is set")
    func testFullNameSingleName() {
        var user = try! DirectusUser(["id": "only-first", "first_name": "Only"])
        #expect(user.fullName == "Only")
        
        user = try! DirectusUser(["id": "only-last", "last_name": "Last"])
        #expect(user.fullName == "Last")
    }
    
    @Test("New user gets UUID assigned as id")
    func testNewUserHasUUID() {
        let user = DirectusUser.newUser(email: "a@b.com", password: "pass")
        #expect(user.id != nil)
        #expect(UUID(uuidString: user.id!) != nil)
    }
    
    @Test("Decoding user with only email succeeds")
    func testPartialJSONDecode() throws {
        let json = #"{"id":"123","email":"test@example.com"}"#.data(using: .utf8)!
        let user = try JSONDecoder().decode(DirectusUser.self, from: json)
        #expect(user.email == "test@example.com")
        #expect(user.id == "123")
    }
    
    @Test("Unknown status value results in nil status")
    func testUnknownStatus() throws {
        let json = #"{"id":"999","status":"phantom"}"#.data(using: .utf8)!
        let user = try JSONDecoder().decode(DirectusUser.self, from: json)
        #expect(user.status == nil)
    }
    
    @Test("Special characters in name fields are handled")
    func testSpecialCharacters() {
        let user = try! DirectusUser([
            "id": "special",
            "first_name": "🚀 New\nLine",
            "last_name": "Üser"
        ])
        #expect(user.firstname == "🚀 New\nLine")
        #expect(user.lastname == "Üser")
        #expect(user.fullName.contains("🚀"))
    }
}
