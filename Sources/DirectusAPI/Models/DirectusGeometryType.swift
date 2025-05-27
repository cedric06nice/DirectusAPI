//
//  DirectusGeometryType.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

@MainActor
struct DirectusGeometryType: Equatable, Codable {
    let type: String
    let coordinates: [Double]
    
    init(type: String, coordinates: [Double]) {
        self.type = type
        self.coordinates = coordinates
    }
    
    static func mapPoint(latitude: Double, longitude: Double) -> DirectusGeometryType {
        .init(type: "Point", coordinates: [longitude, latitude])
    }
    
    static func point(x: Double, y: Double) -> DirectusGeometryType {
        .init(type: "Point", coordinates: [x, y])
    }
    
    var pointLatitude: Double? {
        type == "Point" && coordinates.indices.contains(1) ? coordinates[1] : nil
    }
    
    var pointLongitude: Double? {
        type == "Point" && coordinates.indices.contains(0) ? coordinates[0] : nil
    }
    
    var pointX: Double? {
        type == "Point" && coordinates.indices.contains(0) ? coordinates[0] : nil
    }
    
    var pointY: Double? {
        type == "Point" && coordinates.indices.contains(1) ? coordinates[1] : nil
    }
    
    static func fromJSON(_ json: [String: Any]) -> DirectusGeometryType? {
        guard let type = json["type"] as? String,
              let coords = json["coordinates"] as? [Double] else { return nil }
        return DirectusGeometryType(type: type, coordinates: coords)
    }
    
    func toJSON() -> [String: Any] {
        ["type": type, "coordinates": coordinates]
    }
}
