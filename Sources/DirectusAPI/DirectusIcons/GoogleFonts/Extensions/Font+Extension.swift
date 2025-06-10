//
//  Font+Extension.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 09/06/2025.
//

import SwiftUI

// MARK: - SwiftUI Font extension
public extension Font {
    /// Create a custom font with the given name,size that scales with the body text style and variable font axes.
    ///
    /// ```swift
    ///    Text("Hello world")
    ///        .font(.googleMaterialDesign(
    ///            name: .materialSymbolsOutlined,
    ///            size: 20,
    ///            axes: [
    ///                .weight: 400,
    ///                .opticalSize: 48,
    ///                .fill: 0,
    ///                .grade: 0
    ///            ]
    ///        ))
    /// ```
    static func googleMaterialDesign(
        font: GoogleFont,
        size: CGFloat,
        weight: GoogleFontWeight = .regular,
        opticalSize: GoogleFontOpticalSize = .normal,
        fill: GoogleFontFill = .off,
        grade: GoogleFontGrade = .normalEmphasis,
    ) -> Font {
        let axes: [GoogleFontAxis.Name: CGFloat] = [
            .weight: weight.rawValue,
            .opticalSize: opticalSize.rawValue,
            .fill: fill.rawValue,
            .grade: grade.rawValue
        ]
        guard let font = PlatformFont(name: font.rawValue, size: size, axes: axes) else {
            return .system(size: size)
        }
        
        return Font(font)
    }
}
