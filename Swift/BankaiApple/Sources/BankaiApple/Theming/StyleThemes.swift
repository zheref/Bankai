//
//  StyleTheme.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 21/01/25.
//

import SwiftUI

public enum DesignLanguage {
    case cocoa
    case cupertino
    case material2
    case material3
    case modern
    case fluent
}

public struct StyleTheme {
    let name: String
    let base: DesignLanguage
    
    let regularMajorPadding: CGFloat
    let regularSurroundingPadding: CGFloat
    
    let textFieldHeight: CGFloat
    let textFieldCornerRadius: CGFloat
}

extension StyleTheme {
    
    @MainActor
    static let cocoa: StyleTheme = .init(
        name: "Cocoa",
        base: .cocoa,
        regularMajorPadding: 20.0,
        regularSurroundingPadding: 13.0,
        textFieldHeight: 40.0,
        textFieldCornerRadius: 20.0
    )
    
}

public struct ThemedTextFieldStyle: TextFieldStyle {
    let base: DesignLanguage
    let padding: CGFloat
    let radius: CGFloat = 10.0
    
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(padding)
            .background(Color.white)
            .cornerRadius(radius)
    }
}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder
    func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func modify<Content: View>(_ transform: (Self) -> Content) -> some View {
        transform(self)
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
