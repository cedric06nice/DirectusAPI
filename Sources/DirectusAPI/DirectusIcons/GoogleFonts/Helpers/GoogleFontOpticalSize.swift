//
//  GoogleFontOpticalSize.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 09/06/2025.
//

import Foundation

/// Optical Sizes range from 20dp to 48dp.
///
/// ```swift
/// .small      (20)
/// .normal     (24)
/// .large      (40)
/// .extralarge (48)
/// ```
/// For the image to look the same at different sizes, the stroke weight (thickness) changes as the icon size scales.
/// Optical Size offers a way to automatically adjust the stroke weight when you increase or decrease the symbol size.
public enum GoogleFontOpticalSize: CGFloat {
    case small = 20
    case normal = 24
    case large = 40
    case extralarge = 48
}
