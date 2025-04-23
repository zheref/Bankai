//
//  InnerCapsuleModifier.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 5/03/25.
//

import SwiftUI

struct InnerCapsuleModifier: ViewModifier {
    
    public let cornerRadius: CGFloat
    public let outlineColor: Color
    
    public init(cornerRadius: CGFloat, outlineColor: Color) {
        self.cornerRadius = cornerRadius
        self.outlineColor = outlineColor
    }
    
    public func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        outlineColor,
                        lineWidth: 1
                    )
            )
    }
    
}

extension View {
    
    public func bankaiCapsule(cornerRadius: CGFloat = 10, outlineColor: Color = .gray) -> some View {
        modifier(
            InnerCapsuleModifier(
                cornerRadius: cornerRadius,
                outlineColor: outlineColor
            )
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
    let theme: StyleTheme = .cocoa
    
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
        .bankaiCapsule(
            outlineColor: focusedField == .input ? theme.colors.accent
                : theme.colors.background3
        )
    }
    .background(Color.gray)
    .frame(width: 640, height: 480)
}
#endif
