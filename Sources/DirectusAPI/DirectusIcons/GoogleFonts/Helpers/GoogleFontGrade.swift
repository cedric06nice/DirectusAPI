//
//  GoogleFontGrade.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 09/06/2025.
//

import Foundation

/// Weight and grade affect a symbol's thickness.
/// Adjustments to grade are more granular than adjustments to weight and have a small impact on the size of the symbol.
/// Grade is also available in some text fonts.
/// You can match grade levels between text and symbols for a harmonious visual effect.
///
/// ```swift
/// .veryLowEmphasis  (-25)
/// .lowEmphasis      (-12)
/// .normalEmphasis   (0)
/// .moderateEmphasis (50)
/// .highEmphasis     (100)
/// .highEmphasisPlus (150)
/// .veryHighEmphasis (200)
/// ```
/// For example, if the text font has a -25 grade value, the symbols can match it with a suitable value, say -25.
/// You can use grade for different needs:
/// Low emphasis (e.g. -25 grade): To reduce glare for a light symbol on a dark background, use a low grade.
/// High emphasis (e.g. 200 grade): To highlight a symbol, increase the positive grade.
public enum GoogleFontGrade: CGFloat {
    case veryLowEmphasis = -25
    case lowEmphasis = -12
    case normalEmphasis = 0
    case moderateEmphasis = 50
    case highEmphasis = 100
    case highEmphasisPlus = 150
    case veryHighEmphasis = 200
}
