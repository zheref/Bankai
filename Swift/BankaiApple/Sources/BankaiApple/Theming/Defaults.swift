//
//  Defaults.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 4/03/25.
//

import SwiftUI

extension Palette {
    
    public static let common: Palette = {
        #if os(macOS)
        let totalColor = Color(.textColor)
        let warningColor = Color(.systemYellow)
        let dangerColor = Color(.systemRed)
        let foregroundColor = Color(.labelColor)
        let foreground2Color = Color(.secondaryLabelColor)
        let background1Color = Color(.windowBackgroundColor)
        let border1Color = Color(.separatorColor)
        let background2Color = Color(.controlBackgroundColor)
        let border2Color = Color(.gridColor)
        let background3Color = Color(.underPageBackgroundColor)
        let border3Color = Color(.unemphasizedSelectedContentBackgroundColor)
        let absoluteColor = Color(.textBackgroundColor)
        #else
        let totalColor = Color.primary
        let warningColor = Color(uiColor: .systemYellow)
        let dangerColor = Color(uiColor: .systemRed)
        let foregroundColor = Color(uiColor: .label)
        let foreground2Color = Color(uiColor: .secondaryLabel)
        let background1Color = Color(uiColor: .systemBackground)
        let border1Color = Color(uiColor: .separator)
        let background2Color = Color(uiColor: .secondarySystemBackground)
        let border2Color = Color(uiColor: .secondarySystemGroupedBackground)
        let background3Color = Color(uiColor: .tertiarySystemBackground)
        let border3Color = Color(uiColor: .tertiarySystemGroupedBackground)
        let absoluteColor = Color(uiColor: .systemFill)
        #endif
        
        return .init(
            total: totalColor,
            accent: Color.accentColor,
            warning: warningColor,
            danger: dangerColor,
            foreground: foregroundColor,
            foreground2: foreground2Color,
            background1: background1Color,
            border1: border1Color,
            background2: background2Color,
            border2: border2Color,
            background3: background3Color,
            border3: border3Color,
            absolute: absoluteColor,
            complementaryA: Color.green,
            complementaryB: Color.blue,
            complementaryC: Color.orange
        )
    }()
    
}

extension StyleTheme {
    
    @MainActor
    public static let cocoa: StyleTheme = .init(
        name: "Cocoa",
        design: DesignLanguage.cocoa,
        colors: Palette.common
    )
    
}
