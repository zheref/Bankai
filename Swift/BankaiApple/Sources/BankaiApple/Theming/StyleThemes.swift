//
//  StyleTheme.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 21/01/25.
//

import SwiftUI

// Theme
// Colors -> Palette
// Design Language -> Design (Sizes, Spacing, Paddings, etc)
// Typography -> FontMap

public struct StyleTheme: Hashable {
    public let name: String
    public let design: Design
    public let colors: Palette
    
    public init(name: String, design: Design, colors: Palette) {
        self.name = name
        self.design = design
        self.colors = colors
    }
}

extension StyleTheme {
    public static func == (lhs: StyleTheme, rhs: StyleTheme) -> Bool {
        return lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(colors)
    }
}

public struct ThemedTextFieldStyle: TextFieldStyle {
    let theme: StyleTheme
    let padding: CGFloat
    let radius: CGFloat = 10.0
    
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(padding)
            .background(Color.white)
            .cornerRadius(radius)
    }
}

struct customViewModifier: ViewModifier {
    var roundedCorners: CGFloat
    var textColor: Color

    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white)
            .cornerRadius(roundedCorners)
            .padding(3)
            .foregroundColor(textColor)
            .overlay(RoundedRectangle(cornerRadius: roundedCorners)
                .stroke(Color.white, lineWidth: 2.5))

            .shadow(radius: 10)
    }
}
