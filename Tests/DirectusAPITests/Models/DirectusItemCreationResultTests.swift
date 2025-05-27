//
//  DirectusItemCreationResultTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
@testable import DirectusAPI
import Foundation

@MainActor 
struct DirectusItemCreationResultTests {

    struct DummyItem: Equatable {
        let id: Int
    }

    @Test
    func testSuccessCreatedItemList() {
        let items = [DummyItem(id: 1), DummyItem(id: 2)]
        let result: DirectusItemCreationResult<DummyItem> = .success(items)
        #expect(result.createdItemList == items)
    }

    @Test
    func testSuccessCreatedItem() {
        let items = [DummyItem(id: 42)]
        let result: DirectusItemCreationResult<DummyItem> = .success(items)
        #expect(result.createdItem == DummyItem(id: 42))
    }

    @Test
    func testFailureReturnsNil() {
        let error = DirectusApiError(
            response: nil,
            bodyData: nil,
            customMessage: "Test error"
        )
        let result: DirectusItemCreationResult<DummyItem> = .failure(error)
        #expect(result.createdItem == nil)
        #expect(result.createdItemList == nil)
    }

    @Test
    func testFromDirectusReturnsSuccess() {
        let api = MockDirectusApi()
        let dummyDict: [String: Any] = ["id": 1]
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: nil)!
        let data = try! JSONSerialization.data(withJSONObject: dummyDict)

        api.nextParsedResponse = dummyDict

        let result = DirectusItemCreationResult<DummyItem>.fromDirectus(
            api: api,
            response: response,
            data: data,
            constructor: { dict in
                DummyItem(id: dict["id"] as? Int ?? -1)
            }
        )

        switch result {
        case .success(let items):
            #expect(items.first?.id == 1)
        case .failure:
            #expect(Bool(false), "Expected success, got failure")
        }
    }

    @Test
    func testFromDirectusReturnsEmptyOn204() {
        let api = MockDirectusApi()
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 204,
                                       httpVersion: nil,
                                       headerFields: nil)!
        let data = Data()

        let result = DirectusItemCreationResult<DummyItem>.fromDirectus(
            api: api,
            response: response,
            data: data,
            constructor: { _ in DummyItem(id: 1) }
        )

        switch result {
        case .success(let items):
            #expect(items.isEmpty)
        default:
            #expect(Bool(false), "Expected success, got failure")
        }
    }

    @Test
    func testFromDirectusFailsToParse() {
        let api = MockDirectusApi()
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: nil)!
        let data = Data()
        api.nextParsedResponse = "not a dict"

        let result = DirectusItemCreationResult<DummyItem>.fromDirectus(
            api: api,
            response: response,
            data: data,
            constructor: { _ in DummyItem(id: 1) }
        )

        switch result {
        case .failure:
            #expect(true)
        default:
            #expect(Bool(false), "Expected failure due to parse error")
        }
    }
}
