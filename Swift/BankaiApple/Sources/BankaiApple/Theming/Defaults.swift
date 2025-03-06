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
        let background1Color = Color(.windowBackgroundColor)
        let border1Color = Color(.separatorColor)
        let background2Color = Color(.controlBackgroundColor)
        let border2Color = Color(.gridColor)
        let background3Color = Color(.underPageBackgroundColor)
        let border3Color = Color(.unemphasizedSelectedContentBackgroundColor)
        let absoluteColor = Color(.textBackgroundColor)
        #else
        let totalColor = Color(uiColor: .quinaryLabel)
        let warningColor = Color(uiColor: .systemYellow)
        let dangerColor = Color(uiColor: .systemRed)
        let foregroundColor = Color(uiColor: .labelColor)
        let background1Color = Color(uiColor: .windowBackgroundColor)
        let border1Color = Color(uiColor: .separatorColor)
        let background2Color = Color(uiColor: .controlBackgroundColor)
        let border2Color = Color(uiColor: .gridColor)
        let background3Color = Color(uiColor: .underPageBackgroundColor)
        let border3Color = Color(uiColor: .unemphasizedSelectedContentBackgroundColor)
        let absoluteColor = Color(uiColor: .textBackgroundColor)
        #endif
        
        return .init(
            total: totalColor,
            accent: Color.accentColor,
            warning: warningColor,
            danger: dangerColor,
            foreground: foregroundColor,
            background1: background1Color,
            border1: border1Color,
            background2: background2Color,
            border2: border2Color,
            background3: background3Color,
            border3: border3Color,
            absolute: absoluteColor,
            complementaryA: Color.green,
            complementeryB: Color.blue,
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
