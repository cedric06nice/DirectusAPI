//
//  GoogleVariableFont.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 08/06/2025.
//

import SwiftUI
import CoreText

#if os(macOS)
typealias PlatformFont = NSFont
typealias PlatformFontDescriptor = NSFontDescriptor
#elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
typealias PlatformFont = UIFont
typealias PlatformFontDescriptor = UIFontDescriptor
#endif

// MARK: - UI/NSFont extension
public extension PlatformFont {
    private static func descriptorFor(name: String, axes: [UInt32 : CGFloat]) -> PlatformFontDescriptor {
        PlatformFontDescriptor(fontAttributes: [
            .name: name,
            kCTFontVariationAttribute as PlatformFontDescriptor.AttributeName: axes,
        ])
    }
    
    /// Initialize a font with the given axes using identifiers.
    ///
    /// This initializer expects a dictionary with axis identifiers (`UInt32`) as key.
    /// ```swift
    ///    let axes: [UInt32 : CGFloat] = [
    ///        2003072104: 400, // Weight
    ///    ]
    /// ```
    convenience init?(name: String, size: CGFloat, axes: [UInt32 : CGFloat]) {
        let descriptor = Self.descriptorFor(name: name, axes: axes)
        self.init(descriptor: descriptor, size: size)
    }
    
    /// Initialize a font with the given axes using names.
    ///
    /// This initializer expects a dictionary with axis names (`GoogleFontAxis.Name`) as key.
    /// ```swift
    ///    let axes: [GoogleFontAxis.Name : CGFloat] = [
    ///        .weight: 400, // Weight
    ///    ]
    /// ```
    convenience init?(name: String, size: CGFloat, axes: [GoogleFontAxis.Name : CGFloat]) {
        let axes = Dictionary(uniqueKeysWithValues: axes.map { key, value in
            return (GoogleFontUtils.nameToId(key), value)
        })
        self.init(name: name, size: size, axes: axes)
    }
    
    /// Get all available axes information of the font.
    func allAxes() -> [GoogleFontAxis] {
        let ctFont = CTFontCreateWithName(fontName as CFString, fontDescriptor.pointSize, nil)
        guard let axes = CTFontCopyVariationAxes(ctFont) as? [[String : Any]] else {
            return []
        }
        
        return axes.compactMap(GoogleFontAxis.init(values:))
    }
    
    // MARK: - Set axis.
    /// Returns a new font with the applied axis, using the identifier as key.
    func withAxis(_ id: UInt32, value: CGFloat) -> Self {
        let descriptor = Self.descriptorFor(name: fontName, axes: [
            id: value
        ])
#if os(macOS)
        return Self.init(descriptor: descriptor, size: pointSize)!
#else
        return Self.init(descriptor: descriptor, size: pointSize)
#endif
    }
    
    /// Returns a new font with the applied axis, using the name as key.
    func withAxis(_ name: GoogleFontAxis.Name, value: CGFloat) -> Self {
        let id = GoogleFontUtils.nameToId(name)
        let descriptor = Self.descriptorFor(name: fontName, axes: [
            id: value
        ])
#if os(macOS)
        return Self.init(descriptor: descriptor, size: pointSize)!
#else
        return Self.init(descriptor: descriptor, size: pointSize)
#endif
    }
    
    /// Returns a new font with the applied axex, using the identifier as key.
    func withAxes(_ axes: [UInt32 : CGFloat]) -> Self {
        let descriptor = Self.descriptorFor(name: fontName, axes: axes)
#if os(macOS)
        return Self.init(descriptor: descriptor, size: pointSize)!
#else
        return Self.init(descriptor: descriptor, size: pointSize)
#endif
    }
    
    /// Returns a new font with the applied axex, using the name as key.
    func withAxes(_ axes: [GoogleFontAxis.Name : CGFloat]) -> Self {
        let axes: [UInt32 : CGFloat] = Dictionary(uniqueKeysWithValues: axes.map { key, value in
            return (GoogleFontUtils.nameToId(key), value)
        })
        let descriptor = Self.descriptorFor(name: fontName, axes: axes)
#if os(macOS)
        return Self.init(descriptor: descriptor, size: pointSize)!
#else
        return Self.init(descriptor: descriptor, size: pointSize)
#endif
    }
}
