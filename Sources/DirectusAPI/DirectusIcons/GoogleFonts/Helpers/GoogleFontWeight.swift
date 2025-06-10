//
//  GoogleFontWeight.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 09/06/2025.
//

import Foundation

/// Weight defines the symbol's stroke weight, with a range of weights
///
/// ```swift
/// .thin       (100)
/// .extraLight (200)
/// .light      (300)
/// .regular    (400)
/// .medium     (500)
/// .bold       (600)
/// .heavy      (700)
/// ```
/// Weight can also affect the overall size of the symbol.
public enum GoogleFontWeight: CGFloat, RawRepresentable {
    case thin = 100
    case extraLight = 200
    case light = 300
    case regular = 400
    case medium = 500
    case bold = 600
    case heavy = 700
    
    init?(string: String) {
        switch string.lowercased() {
        case "thin": self = .thin
        case "extralight": self = .extraLight
        case "light": self = .light
        case "regular": self = .regular
        case "medium": self = .medium
        case "bold": self = .bold
        case "heavy": self = .heavy
        default: return nil
        }
    }
}
