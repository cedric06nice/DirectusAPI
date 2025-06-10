//
//  GoogleFontAxis.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 08/06/2025.
//

import SwiftUI

// MARK: - Font Axis struct
/// Description of a single font axis.
public struct GoogleFontAxis: Identifiable, Hashable, Equatable {
	public let id: UInt32
	public let name: Name
	public let description: String

	public let minimumValue: CGFloat
	public let maximumValue: CGFloat
	public let defaultValue: CGFloat

	init?(values: [String : Any]) {
		guard
			let id = values["NSCTVariationAxisIdentifier"] as? UInt32,
			let description = values["NSCTVariationAxisName"] as? String,
			let minimum = values["NSCTVariationAxisMinimumValue"] as? CGFloat,
			let maximum = values["NSCTVariationAxisMaximumValue"] as? CGFloat,
			let `default` = values["NSCTVariationAxisDefaultValue"] as? CGFloat
		else {
			return nil
		}

		self.id = id
        self.name = Name(rawValue: GoogleFontUtils.idToName(id))
		self.description = description
		self.minimumValue = minimum
		self.maximumValue = maximum
		self.defaultValue = `default`
	}

	/// An axis name.
	///
	/// ```swift
    /// let weightAxis: GoogleFontAxis.Name = .weight
    /// let fillAxis: GoogleFontAxis.Name = .fill
    /// let gradeAxis: GoogleFontAxis.Name = .grade
    /// let opticalSizeAxis: GoogleFontAxis.Name = .opticalSize
	/// ```
	public enum Name: CustomStringConvertible, ExpressibleByStringLiteral, Hashable {
        case weight
        case fill
        case grade
		case opticalSize
        
		public init(rawValue: String) {
			self = switch rawValue {
			case "wght": .weight
            case "FILL": .fill
            case "GRAD": .grade
            case "opsz": .opticalSize
            default: ""
            }
		}

		public init(stringLiteral value: String) {
			self.init(rawValue: value)
		}

		public var description: String {
			switch self {
			case .weight: "wght"
            case .fill: "FILL"
            case .grade: "GRAD"
            case .opticalSize: "opsz"
			}
		}
	}
}
