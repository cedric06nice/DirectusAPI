//
//  MockDirectusApiManagerTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 31/05/2025.
//

import Testing
@testable import DirectusAPI

@MainActor
@Suite
struct MockDirectusApiManagerTests {

    private class TestItem: DirectusData, DirectusCollection {
        static var collectionMetadata = CollectionMetadata(
            endpointName: "test",
            defaultFields: "*",
            endpointPrefix: "/",
            webSocketEndPoint: nil,
            defaultUpdateFields: nil
        )
        var name: String = "name"
    }
    
    @Test
    func testLoginDirectusUserRecordsArgumentsAndReturnsMockedValue() async throws {
        let mock = MockDirectusApiManager()
        let expected = DirectusLoginResult(type: .success)
        mock.enqueueReturn(expected)

        let result = try await mock.loginDirectusUser(username: "user", password: "pass", oneTimePassword: "123456")

        #expect(result.type == .success)
        #expect(mock.calledMethods.contains("loginDirectusUser"))
        #expect(mock.receivedArguments["username"] as? String == "user")
    }

    @Test
    func testLogoutThrowsWhenReturnQueueEmpty() async {
        let mock = MockDirectusApiManager()
        await #expect(throws: Error.self) {
            try await mock.logoutDirectusUser()
        }
    }

    @Test
    func testUploadFileReturnsMockedDirectusFile() async throws {
        let mock = MockDirectusApiManager()
        let file = try DirectusFile(["id": "file123"])
        mock.enqueueReturn(file)

        let result = try await mock.uploadFile(
            fileBytes: [1, 2, 3],
            filename: "test.png",
            title: "Title",
            contentType: "image/png",
            folder: "images",
            storage: "local"
        )

        #expect(result.id == "file123")
        #expect(mock.calledMethods.contains("uploadFile"))
    }

    @Test
    func testDeleteFileReturnsTrue() async throws {
        let mock = MockDirectusApiManager()
        mock.enqueueReturn(true)

        let result = try await mock.deleteFile(fileId: "abc")
        #expect(result == true)
        #expect(mock.receivedArguments["fileId"] as? String == "abc")
    }

    @Test
    func testFindListOfItemsWithResultReturnsFailureWhenEmpty() async {
        let mock = MockDirectusApiManager()
        let result: MockResult<[TestItem]> = await mock.findListOfItemsWithResult(
            filter: nil, sortBy: nil, fields: nil,
            limit: nil, offset: nil, requestIdentifier: nil,
            canUseCache: false, canSaveCache: false,
            fallbackToStaleCache: false, maxCacheAge: 0
        )

        switch result {
        case .failure:
            #expect(Bool(true))
        case .success:
            #expect(Bool(false), "Expected failure, got success")
        }
    }
    
    @Test
    func testRegisterUserReturnsToken() async throws {
        let mock = MockDirectusApiManager()
        mock.enqueueReturn(true)
        
        let result = try await mock.registerDirectusUser(email: "test@example.com", password: "123456", firstname: nil, lastname: nil)
        
        #expect(result)
        #expect(mock.calledMethods.contains("registerDirectusUser"))
        #expect(mock.receivedArguments["email"] as? String == "test@example.com")
    }
    
    @Test
    func testCreateItemReturnsItem() async throws {
        let mock = MockDirectusApiManager()
        let item = try TestItem(["id": "1", "name": "name"])
        mock.enqueueReturn(DirectusItemCreationResult<TestItem>.mocked(item))
                
        let result = try await mock.createNewItem(objectToCreate: item, fields: nil)
        #expect(result.createdItem?.name == "name")
        #expect(mock.calledMethods.contains("createNewItem"))
    }
    
    @Test
    func testUpdateItemReturnsItem() async throws {
        let mock = MockDirectusApiManager()
        let item = try TestItem(["id": "1", "name": "name"])
        mock.enqueueReturn(item as TestItem)
        
        let updated = try await mock.updateItem(objectToUpdate: item, fields: nil, force: false)
        
        #expect(updated.name == "name")
        #expect(mock.calledMethods.contains("updateItem"))
    }
    
    @Test
    func testUpdateItemThrowsWhenNoReturnValue() async {
        let mock = MockDirectusApiManager()
        let item = try! TestItem(["id": "2", "name": "fail"])
        await #expect(throws: Error.self) {
            _ = try await mock.updateItem(objectToUpdate: item, fields: nil, force: false)
        }
    }
    
    @Test
    func testUpdateItemWithEmptyFieldsReturnsItem() async throws {
        let mock = MockDirectusApiManager()
        let item = try TestItem(["id": "3", "name": "name"])
        mock.enqueueReturn(item as TestItem)
        
        let result = try await mock.updateItem(objectToUpdate: item, fields: "", force: false)
        
        #expect(result.name == "name")
        #expect(mock.calledMethods.contains("updateItem"))
        #expect((mock.receivedArguments["fields"] as? String) == "")
    }
    
    @Test
    func testDeleteItemReturnsTrue() async throws {
        let mock = MockDirectusApiManager()
        mock.enqueueReturn(true)
        
        let result = try await mock.deleteItem(
            objectId: "id",
            ofType: TestItem.self,
            mustBeAuthenticated: true
        )
        
        #expect(result == true)
        #expect(mock.calledMethods.contains("deleteItem"))
    }
    
    @Test
    func testRequestPasswordResetReturnsTrue() async throws {
        let mock = MockDirectusApiManager()
        mock.enqueueReturn(true)
        
        let result = try await mock.requestPasswordReset(
            email: "reset@example.com",
            resetUrl: nil
        )
        
        #expect(result == true)
        #expect(mock.calledMethods.contains("requestPasswordReset"))
    }
    
    @Test
    func testUpdateFileReturnsFile() async throws {
        let mock = MockDirectusApiManager()
        let file = try DirectusFile(["id": "updated"])
        mock.enqueueReturn(file)
        
        let result = try await mock.updateExistingFile(
            fileBytes: [9, 9],
            fileId: "updated",
            filename: "updated.png", 
            contentType: "image/png"
        )
        
        #expect(result.id == "updated")
        #expect(mock.calledMethods.contains("updateExistingFile"))
    }

}
