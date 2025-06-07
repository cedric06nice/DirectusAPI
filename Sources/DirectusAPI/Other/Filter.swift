//
//  Filter.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

@MainActor
public protocol Filter {
    var asJSON: String { get }
    var asDictionary: [String: Any] { get }
}

@MainActor
public enum FilterOperator: String {
    case equals = "_eq"
    case notEqual = "_neq"
    case lessThan = "_lt"
    case lessThanOrEqual = "_lte"
    case greaterThan = "_gt"
    case greaterThanOrEqual = "_gte"
    case oneOf = "_in"
    case notOneOf = "_nin"
    case isNull = "_null"
    case isNotNull = "_nnull"
    case contains = "_contains"
    case notContains = "_ncontains"
    case startWith = "_starts_with"
    case notStartWith = "_nstarts_with"
    case endWith = "_ends_with"
    case notEndWith = "_nends_with"
    case between = "_between"
    case notBetween = "_nbetween"
    case isEmpty = "_empty"
    case isNotEmpty = "_nempty"
}

@MainActor
public struct PropertyFilter: Filter {
    let field: String
    let `operator`: FilterOperator
    let value: Any
    
    public var asJSON: String {
        let testObject = [field: [self.operator.rawValue: value]]
        guard JSONSerialization.isValidJSONObject(testObject) else {
            return "{ \"\(field)\": { \"\(self.operator.rawValue)\": null } }"
        }
        
        let container = [field: [self.operator.rawValue: value]]
        let data = try? JSONSerialization.data(withJSONObject: container, options: [])
        return data.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }
    
    public var asDictionary: [String: Any] {
        return [field: [`operator`.rawValue: value]]
    }
}

@MainActor
public enum LogicalOperator: String {
    case and = "_and"
    case or = "_or"
}

@MainActor
public struct LogicalOperatorFilter: Filter {
    let `operator`: LogicalOperator
    let children: [Filter]
    
    public var asJSON: String {
        let childJSON = children.map { $0.asJSON }.joined(separator: " , ")
        return "{ \"\(`operator`.rawValue)\": [ \(childJSON) ] }"
    }
    
    public var asDictionary: [String: Any] {
        let childDictionaries = children.map { $0.asDictionary }
        return [`operator`.rawValue: childDictionaries]
    }
}

@MainActor
public struct RelationFilter: Filter {
    let propertyName: String
    let linkedObjectFilter: Filter
    
    public var asJSON: String {
        return "{ \"\(propertyName)\": \(linkedObjectFilter.asJSON) }"
    }
    
    public var asDictionary: [String: Any] {
        return [propertyName: linkedObjectFilter.asDictionary]
    }
}
