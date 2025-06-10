//
//  DirectusIcon.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 08/06/2025.
//

import SwiftUI

public struct DirectusIcon: View {
    private var name: String
    private var size: CGFloat?
    private var font: GoogleFont = .materialSymbolsOutlined
    private var weight: GoogleFontWeight = .regular
    private var fill: GoogleFontFill = .off
    private var opticalSize: GoogleFontOpticalSize = .normal
    private var grade: GoogleFontGrade = .normalEmphasis
    
    @Environment(\.font) private var environmentFont
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.legibilityWeight) private var legibilityWeight

    public var body: some View {
        
        let fontSize: CGFloat = size ?? scaledFontSize(
            for: .inferred(from: environmentFont),
            dynamicTypeSize: dynamicTypeSize
        )

        let fontWeight: GoogleFontWeight = {
            if legibilityWeight != .regular {
                switch legibilityWeight.self {
                case .regular: return .regular
                case .bold: return .bold
                case .none: return .regular
                case .some(_): return .bold
                }
            }
            return weight
        }()
        
        Text(name)
            .font(
                .googleMaterialDesign(
                    font: font,
                    size: fontSize,
                    weight: fontWeight,
                    opticalSize: opticalSize,
                    fill: fill,
                    grade: grade
                )
            )
    }
}

extension DirectusIcon {
    public init(_ name: String,
                size: CGFloat? = nil,
                font: GoogleFont = .materialSymbolsOutlined,
                weight: GoogleFontWeight = .regular,
                fill: GoogleFontFill = .off,
                opticalSize: GoogleFontOpticalSize = .normal,
                grade: GoogleFontGrade = .normalEmphasis) {
        self.name = name
        self.size = size
        self.font = font
        self.weight = weight
        self.fill = fill
        self.opticalSize = opticalSize
        self.grade = grade
    }
}

extension DirectusIcon {
    func scaledFontSize(for textStyle: PlatformFont.TextStyle, dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        let baseFont = PlatformFont.preferredFont(forTextStyle: textStyle)
#if os(macOS)
        let scale: CGFloat = switch dynamicTypeSize {
        case .xSmall:         0.82
        case .small:          0.88
        case .medium:         0.95
        case .large:          1.0
        case .xLarge:         1.12
        case .xxLarge:        1.23
        case .xxxLarge:       1.35
        case .accessibility1: 1.64
        case .accessibility2: 1.95
        case .accessibility3: 2.35
        case .accessibility4: 2.76
        case .accessibility5: 3.12
        @unknown default:     1.0
        }
        return baseFont.pointSize * scale
#elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        let sizeCategory = UIContentSizeCategory(dynamicTypeSize)
        let traits = UITraitCollection(preferredContentSizeCategory: sizeCategory)
        return metrics.scaledFont(for: baseFont, compatibleWith: traits).pointSize
#endif
    }
}

#Preview {
    let _ = DirectusFonts.registerAll()
    let name1 = "account_circle"
    ScrollView {
        Label {
            Text(name1.capitalized)
        } icon: {
            DirectusIcon(name1)
        }
        .font(.largeTitle)
        .fontWeight(.heavy)
        Label {
            Text(name1.capitalized)
        } icon: {
            DirectusIcon(name1, fill: .on)
        }
        .font(.caption2.bold())
        .dynamicTypeSize(.accessibility5)
    }
}
