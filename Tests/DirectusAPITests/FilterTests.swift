//
//  FilterTests.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 27/05/2025.
//

import Testing
@testable import DirectusAPI

@MainActor
struct FilterTests {

    @Test
    func testPropertyFilterAsDictionary() {
        let filter = PropertyFilter(field: "age", operator: .greaterThan, value: 21)
        let dict = filter.asDictionary
        #expect(dict["age"] as? [String: Any] != nil)
        #expect((dict["age"] as! [String: Any])["_gt"] as? Int == 21)
    }

    @Test
    func testPropertyFilterAsJSON() {
        let filter = PropertyFilter(field: "name", operator: .equals, value: "Alice")
        let json = filter.asJSON
        #expect(json.contains("\"name\""))
        #expect(json.contains("\"_eq\""))
        #expect(json.contains("\"Alice\""))
    }

    @Test
    func testLogicalOperatorFilterAsDictionary() {
        let filter1 = PropertyFilter(field: "age", operator: .greaterThan, value: 18)
        let filter2 = PropertyFilter(field: "verified", operator: .equals, value: true)
        let logic = LogicalOperatorFilter(operator: .and, children: [filter1, filter2])
        let dict = logic.asDictionary
        #expect(dict["_and"] != nil)
        #expect((dict["_and"] as? [[String: Any]])?.count == 2)
    }

    @Test
    func testLogicalOperatorFilterAsJSON() {
        let f1 = PropertyFilter(field: "x", operator: .lessThan, value: 10)
        let f2 = PropertyFilter(field: "y", operator: .greaterThanOrEqual, value: 5)
        let logic = LogicalOperatorFilter(operator: .or, children: [f1, f2])
        let json = logic.asJSON
        #expect(json.contains("_or"))
        #expect(json.contains("_lt"))
        #expect(json.contains("_gte"))
    }

    @Test
    func testRelationFilterAsDictionary() {
        let inner = PropertyFilter(field: "status", operator: .equals, value: "active")
        let relation = RelationFilter(propertyName: "profile", linkedObjectFilter: inner)
        let dict = relation.asDictionary
        #expect(dict["profile"] != nil)
        let subDict = dict["profile"] as? [String: Any]
        #expect((subDict?["status"] as? [String: Any])?["_eq"] as? String == "active")
    }

    @Test
    func testRelationFilterAsJSON() {
        let inner = PropertyFilter(field: "role", operator: .notEqual, value: "banned")
        let relation = RelationFilter(propertyName: "account", linkedObjectFilter: inner)
        let json = relation.asJSON
        #expect(json.contains("account"))
        #expect(json.contains("_neq"))
        #expect(json.contains("banned"))
    }

    @Test
    func testComplexNestedFilter() {
        let f1 = PropertyFilter(field: "type", operator: .equals, value: "admin")
        let f2 = PropertyFilter(field: "active", operator: .equals, value: true)
        let logic = LogicalOperatorFilter(operator: .and, children: [f1, f2])
        let relation = RelationFilter(propertyName: "user", linkedObjectFilter: logic)

        let dict = relation.asDictionary
        #expect(dict["user"] != nil)
        let nested = dict["user"] as? [String: Any]
        #expect(nested?["_and"] != nil)
    }
}
