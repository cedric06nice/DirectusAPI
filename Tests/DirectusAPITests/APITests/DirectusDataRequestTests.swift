//
//  DirectusDataRequestTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
@testable import DirectusAPI
import Foundation

struct DirectusDataRequestTests {
    @MainActor
    @Test func testGetListOfItemsWithFields() async {
        let sut = await DirectusTestHelpers.makeAuthenticatedDirectusAPI()
        let request = sut.prepareGetListOfItemsRequest(
            endpointName: "article",
            endpointPrefix: "/items/",
            fields: "*.*"
        ).request as! URLRequest
        
        #expect(request.url?.absoluteString == "http://api.com/items/article?fields=*.*")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(DirectusTestHelpers.defaultAccessToken)")
    }
    
    @Test
    func testGetListOfItemsWithFilter() async {
        let sut = await DirectusTestHelpers.makeAuthenticatedDirectusAPI()
        let filter = await PropertyFilter(
            field: "title",
            operator: .equals,
            value: "A"
        )
        let request = await sut.prepareGetListOfItemsRequest(
            endpointName: "article",
            endpointPrefix: "/items/",
            filter: filter
        ).request as! URLRequest
        
        #expect(request.url?.absoluteString.contains("filter") == true)
        #expect(request.url?.absoluteString.contains("title") == true)
    }
    
    @Test
    func testGetListOfItemsWithSort() async {
        let sut = await DirectusTestHelpers.makeAuthenticatedDirectusAPI()
        let sort = await [
            SortProperty(name: "score", ascending: false),
            SortProperty(name: "level")
        ]
        let request = await sut.prepareGetListOfItemsRequest(
            endpointName: "article",
            endpointPrefix: "/items/",
            sortBy: sort
        ).request as! URLRequest
        
        #expect(
            request.url?.absoluteString.contains("sort=-score,level") == true
        )
    }
    
    @Test
    func testGetListOfItemsWithLimit() async {
        let sut = await DirectusTestHelpers.makeAuthenticatedDirectusAPI()
        let request = await sut.prepareGetListOfItemsRequest(
            endpointName: "article",
            endpointPrefix: "/items/",
            limit: 10
        ).request as! URLRequest
        
        #expect(request.url?.absoluteString.contains("limit=10") == true)
    }
    
    @Test
    func testGetListOfItemsWithOffset() async {
        let sut = await DirectusTestHelpers.makeAuthenticatedDirectusAPI()
        let request = await sut.prepareGetListOfItemsRequest(
            endpointName: "article",
            endpointPrefix: "/items/",
            offset: 10
        ).request as! URLRequest
        
        #expect(request.url?.absoluteString.contains("offset=10") == true)
    }
    
    @Test
    func testGetListOfItemsWithFilterSortLimit() async {
        let sut = await DirectusTestHelpers.makeAuthenticatedDirectusAPI()
        let filter = await PropertyFilter(
            field: "title",
            operator: .equals,
            value: "A"
        )
        let sort = await [
            SortProperty(name: "score", ascending: false),
            SortProperty(name: "level")
        ]
        let request = await sut.prepareGetListOfItemsRequest(
            endpointName: "article",
            endpointPrefix: "/items/",
            filter: filter,
            sortBy: sort,
            limit: 10
        ).request as! URLRequest
        
        let url = request.url?.absoluteString ?? ""
        #expect(url.contains("filter"))
        #expect(url.contains("limit=10"))
        #expect(url.contains("sort=-score,level"))
    }
    
    @Test
    func testGetListOfItemsWithSpecialCharacters() async {
        let sut = await DirectusTestHelpers.makeAuthenticatedDirectusAPI()
        let filter = await PropertyFilter(
            field: "date",
            operator: .between,
            value: ["$NOW", "$NOW(+2 weeks)"]
        )
        let request = await sut.prepareGetListOfItemsRequest(
            endpointName: "article",
            endpointPrefix: "/items/",
            filter: filter
        ).request as! URLRequest
        
        let url = request.url?.absoluteString ?? ""
        #expect(url.contains("filter"))
        #expect(url.contains("$NOW"))
//        #expect(url.contains("%24NOW")) // Encoded $
    }
}
