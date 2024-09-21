//
//  SwiftUI-MiniComponents.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 21/09/24.
//

import SwiftUI

#if canImport(UIKit)
@MainActor
public var isWide: Bool { UIDevice.current.userInterfaceIdiom != .phone }
#else
public var isWide = false
#endif

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)

#endif

@MainActor
@ViewBuilder
public func ButtonLabel(glyph: String, text: String) -> some View {
    HStack {
        Image(systemName: glyph)
        if isWide { Text(text) }
    }
}
