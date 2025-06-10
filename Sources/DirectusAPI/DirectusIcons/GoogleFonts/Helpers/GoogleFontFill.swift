//
//  GoogleFontFill.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 09/06/2025.
//

import Foundation

/// Fill gives you the ability to modify the default icon style.
/// A single icon can render both unfilled and filled states.
/// To convey a state transition, use the fill axis for animation or interaction.
///
/// ```
/// .off for default
/// .on  for completely filled.
/// ```
/// Along with the weight axis, the fill also impacts the look of the icon.
public enum GoogleFontFill: CGFloat {
    case off = 0
    case on = 1
}
