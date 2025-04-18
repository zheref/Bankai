//
//  InnerCapsuleModifier.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 5/03/25.
//

import SwiftUI

struct InnerCapsuleModifier: ViewModifier {
    
    public let cornerRadius: CGFloat
    public let isFocused: Bool
    public let theme: StyleTheme
    
    public init(cornerRadius: CGFloat, isFocused: Bool, theme: StyleTheme) {
        self.cornerRadius = cornerRadius
        self.isFocused = isFocused
        self.theme = theme
    }
    
    public func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isFocused ? theme.colors.accent : theme.colors.background3,
                        lineWidth: 1
                    )
            )
    }
    
}

extension View {
    
    public func bankaiCapsule(cornerRadius: CGFloat = 10, isFocused: Bool = false, theme: StyleTheme = .cocoa) -> some View {
        modifier(
            InnerCapsuleModifier(cornerRadius: cornerRadius, isFocused: isFocused, theme: theme)
        )
    }
}

#if DEBUG
public enum PreviewField {
    case input
}

@available(macOS 14.0, iOS 17.0, *)
#Preview {
    @Previewable @State var someInput: String = ""
    @FocusState var focusedField: PreviewField?
    
    VStack {
        HStack {
            TextField("",
                      text: $someInput,
                      prompt: Text("Enter input here")
            )
            .textFieldStyle(.plain)
            .background(StyleTheme.cocoa.colors.background2)
            .frame(maxWidth: 300)
        }
        .padding(10)
        .frame(minHeight: 40)
        .background(StyleTheme.cocoa.colors.background2)
        .bankaiCapsule(isFocused: focusedField == .input)
    }
    .background(Color.gray)
    .frame(width: 640, height: 480)
}
#endif
