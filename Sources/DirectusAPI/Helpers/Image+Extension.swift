//
//  Image+Extension.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 30/05/2025.
//

import SwiftUI
import OSLog

extension Logger {
    internal static let icon = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.cedric06nice.DirectusAPI",
        category: "IconMapper"
    )
}

private class SymbolMap {
    @MainActor static let shared = SymbolMap()
    private var mapping: [String: String] = [:]
    
    private init() {
        loadJSON()
    }
    
    private func loadJSON() {
        guard let url = Bundle.main.url(forResource: "materialToSFSymbols", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
            Logger.icon.error("❌ Failed to load or parse materialToSFSymbols.json")
            return
        }
        self.mapping = decoded
    }
    
    func sfSymbol(for materialSymbol: String) -> String {
        if let sf = mapping[materialSymbol] {
            return sf
        } else {
            Logger.icon.warning("⚠️ Unknown Material Symbol: \(materialSymbol, privacy: .public)")
            return "questionmark.circle"
        }
    }
}

public extension Image {
    /// Initializes an SF Symbol `Image` from a Material Symbol name using a JSON-based mapping
    @MainActor
    init(materialSymbol name: String) {
        let sfSymbol = SymbolMap.shared.sfSymbol(for: name)
        self.init(systemName: sfSymbol)
    }
}
