//
//  DirectusFonts.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 10/06/2025.
//

import Foundation
import CoreText

public enum DirectusFonts {
    public static func registerAll() {
        registerFont(named: "MaterialSymbolsOutlined-VariableFont_FILL,GRAD,opsz,wght")
        registerFont(named: "MaterialSymbolsRounded-VariableFont_FILL,GRAD,opsz,wght")
        registerFont(named: "MaterialSymbolsSharp-VariableFont_FILL,GRAD,opsz,wght")
    }

    private static func registerFont(named name: String) {
        guard let url = Bundle.module.url(forResource: name, withExtension: "ttf") else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
