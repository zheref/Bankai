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
public let isWide = false
#endif

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
import UIKit
#else
import AppKit
#endif

@MainActor
@ViewBuilder
public func ButtonLabel(glyph: String, text: String, short: String? = nil) -> some View {
    HStack {
        #if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
        Image(systemName: glyph)
        #else
        if #available(macOS 11.0, *) {
            if OSEnv.prior(to: .bigSur) {
                Image(nsImage: .init(imageLiteralResourceName: glyph))
            } else {
                Image(systemName: glyph)
            }
        } else {
            Image(nsImage: .init(imageLiteralResourceName: glyph))
        }
        #endif
        if isWide { Text(text) }
        else if let short { Text(short) }
    }
}
