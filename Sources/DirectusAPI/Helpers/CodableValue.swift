//
//  CodableValue.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

enum CodableValue: Codable {
    case string(String), int(Int), double(Double), bool(Bool)
    case array([CodableValue]), dictionary([String: CodableValue])
    case null
    
    init(any value: Any) {
        switch value {
        case let value as String: self = .string(value)
        case let value as Int: self = .int(value)
        case let value as Double: self = .double(value)
        case let value as Bool: self = .bool(value)
        case let value as [Any]: self = .array(value.map(CodableValue.init))
        case let value as [String: Any]:
            self = .dictionary(value.mapValues(CodableValue.init))
        default: self = .null
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .array(let values): try container.encode(values)
        case .dictionary(let dict): try container.encode(dict)
        case .null: try container.encodeNil()
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let val = try? container.decode(Int.self) { self = .int(val) }
        else if let val = try? container.decode(Double.self) { self = .double(val) }
        else if let val = try? container.decode(Bool.self) { self = .bool(val) }
        else if let val = try? container.decode(String.self) { self = .string(val) }
        else if let val = try? container.decode([CodableValue].self) { self = .array(val) }
        else if let val = try? container.decode([String: CodableValue].self) { self = .dictionary(val) }
        else { self = .null }
    }
}
