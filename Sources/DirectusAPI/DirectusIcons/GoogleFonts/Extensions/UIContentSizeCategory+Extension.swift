//
//  UIContentSizeCategory+Extension.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 09/06/2025.
//

import SwiftUI

#if !os(macOS)
extension UIContentSizeCategory {
    init(_ dynamicSize: DynamicTypeSize) {
        switch dynamicSize {
        case .xSmall: self = .extraSmall
        case .small: self = .small
        case .medium: self = .medium
        case .large: self = .large
        case .xLarge: self = .extraLarge
        case .xxLarge: self = .extraExtraLarge
        case .xxxLarge: self = .extraExtraExtraLarge
        case .accessibility1: self = .accessibilityMedium
        case .accessibility2: self = .accessibilityLarge
        case .accessibility3: self = .accessibilityExtraLarge
        case .accessibility4: self = .accessibilityExtraExtraLarge
        case .accessibility5: self = .accessibilityExtraExtraExtraLarge
        @unknown default: self = .large
        }
    }
}
#endif
