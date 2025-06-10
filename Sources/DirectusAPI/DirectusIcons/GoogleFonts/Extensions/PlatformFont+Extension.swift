//
//  PlatformFont+Extension.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 09/06/2025.
//

import SwiftUI

extension PlatformFont {
    static func preferredFont(from font: Font, width: LegibilityWeight) -> PlatformFont {
        
        let textStyle: PlatformFont.TextStyle = switch font {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .caption: .caption1
        case .caption2: .caption2
        case .footnote: .footnote
        case .body: fallthrough
        default: .body
        }
        
        let textWidth: PlatformFont.Weight = switch width {
        case .bold: .bold
        case .regular: .regular
        @unknown default: .regular
        }
        
        let baseFont = PlatformFont.preferredFont(
            forTextStyle: textStyle
        )
        
#if os(macOS)
        let descriptor = baseFont.fontDescriptor.withSymbolicTraits(.bold)
        let boldDescriptor = descriptor.addingAttributes([
            PlatformFontDescriptor.AttributeName.traits: [
                PlatformFontDescriptor.TraitKey.weight: textWidth
            ]
        ])
        if let boldFont = PlatformFont(descriptor: boldDescriptor, size: 0) {
            return boldFont
        }
        return baseFont
#else
        let descriptor = baseFont.fontDescriptor.withSymbolicTraits(.traitBold)
        let boldDescriptor = descriptor?.addingAttributes([
            PlatformFontDescriptor.AttributeName.traits: [
                PlatformFontDescriptor.TraitKey.weight: textWidth
            ]
        ]) ?? .preferredFontDescriptor(withTextStyle: textStyle)
        let boldFont = PlatformFont(descriptor: boldDescriptor, size: 0)
        return UIFontMetrics(forTextStyle: textStyle)
            .scaledFont(for: boldFont)
#endif
        
    }
    
    static func fontWeight(from font: Font?, width: LegibilityWeight) -> PlatformFont.Weight {
        guard let font else {
            return width == .bold ? .bold : .regular
        }
        let description = String(describing: font).lowercased()
        if description.contains("bold") || width == .bold {
            return .bold
        }
        return .regular
    }
}

extension PlatformFont.TextStyle {
    static func inferred(from font: Font?) -> PlatformFont.TextStyle {
        switch font {
        case .some(.largeTitle): return .largeTitle
        case .some(.title): return .title1
        case .some(.title2): return .title2
        case .some(.title3): return .title3
        case .some(.headline): return .headline
        case .some(.subheadline): return .subheadline
        case .some(.callout): return .callout
        case .some(.caption): return .caption1
        case .some(.caption2): return .caption2
        case .some(.footnote): return .footnote
        case .some(.body), .some(_): return .body
        default: return .body
        }
    }
}
