//
//  Palette.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 4/03/25.
//

import SwiftUI

public struct Palette: Sendable, Hashable {
    public let total: Color
    public let accent: Color
    public let warning: Color
    public let danger: Color
    
    public let foreground: Color
    public let foreground2: Color
    
    public let surface: Color
    public let block: Color
    
    public let background1: Color
    public let border1: Color
    public let background2: Color
    public let border2: Color
    public let background3: Color
    public let border3: Color
    
    public let absolute: Color
    
    public let complementaryA: Color
    public let complementaryB: Color
    public let complementaryC: Color
    
    public init(
        total: Color,
        accent: Color,
        warning: Color,
        danger: Color,
        surface: Color,
        block: Color,
        foreground: Color,
        foreground2: Color,
        background1: Color,
        border1: Color,
        background2: Color,
        border2: Color,
        background3: Color,
        border3: Color,
        absolute: Color,
        complementaryA: Color,
        complementaryB: Color,
        complementaryC: Color
    ) {
        self.total = total
        self.accent = accent
        self.warning = warning
        self.danger = danger
        self.surface = surface
        self.block = block
        self.foreground = foreground
        self.foreground2 = foreground2
        self.background1 = background1
        self.border1 = border1
        self.background2 = background2
        self.border2 = border2
        self.background3 = background3
        self.border3 = border3
        self.absolute = absolute
        self.complementaryA = complementaryA
        self.complementaryB = complementaryB
        self.complementaryC = complementaryC
    }
}
