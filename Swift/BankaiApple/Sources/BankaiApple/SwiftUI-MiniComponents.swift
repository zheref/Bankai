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
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

@MainActor
@ViewBuilder
public func ButtonLabel(glyph: String, text: String, short: String? = nil) -> some View {
    HStack {
        if #available(macOS 11.0, *) {
            Image(systemName: glyph)
        } else {
            #if os(macOS)
            EmptyView()
            #else
            Image(uiImage: UIImage(systemName: glyph))
            #endif
        }
        if isWide { Text(text) }
        else if let short { Text(short) }
    }
}
