//
//  TextInput.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 3/9/25.
//

import SwiftUI

@available(macOS 12.0, iOS 17.0, *)
public struct TextInput<FocusedField: Hashable>: View {
    
    @Binding var text: String
    var focusedField: FocusState<FocusedField?>.Binding
    var focusedKey: FocusedField?
    let icon: Image?
    let placeholder: String
    let onSubmit: () -> Void
    let resolveReadyToConfirm: (String) -> Bool
    let ctaTitle: String?
    let theme: StyleTheme
    
    public init(
        text: Binding<String>,
        focusedField: FocusState<FocusedField?>.Binding,
        focusedKey: FocusedField?,
        icon: Image? = nil,
        placeholder: String = "",
        onSubmit: @escaping () -> Void = { },
        resolveReadyToConfirm: @escaping (String) -> Bool = { _ in true },
        ctaTitle: String? = nil,
        theme: StyleTheme? = nil
    ) {
        self._text = text
        self.focusedField = focusedField
        self.focusedKey = focusedKey
        self.icon = icon
        self.placeholder = placeholder
        self.onSubmit = onSubmit
        self.resolveReadyToConfirm = resolveReadyToConfirm
        self.ctaTitle = ctaTitle
        self.theme = theme ?? .cocoa
    }
    
    private var isFocused: Bool {
        focusedField.wrappedValue == focusedKey
    }
    
    public var body: some View {
        HStack {
            if let icon {
                icon
            }
            
            TextField("",
                      text: $text,
                      prompt: Text(placeholder))
            .focused(focusedField,
                     equals: focusedKey)
            .textFieldStyle(.plain)
            .onSubmit(onSubmit)
            .onReturnPress(perform: {
                onSubmit()
                return .handled
            })
            .background(theme.colors.background2)
            
            Spacer()
            
            if let ctaTitle, isFocused, resolveReadyToConfirm(text) {
                Button {
                    onSubmit()
                } label: {
                    Text(ctaTitle)
                }
            }
        }
        .padding(10)
        .frame(minHeight: 40)
        .background(theme.colors.background2)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isFocused ? theme.colors.accent : theme.colors.background3,
                    lineWidth: 1
                )
        )
    }
    
}

@available(macOS 14.0, iOS 17.0, *)
#Preview {
    @Previewable @State var text: String = ""
    @Previewable @FocusState var focusedField: AnyHashable?
    
    NavigationStack {
        VStack {
            TextInput(
                text: $text,
                focusedField: $focusedField,
                focusedKey: "",
                icon: Image(systemName: "plus"),
                placeholder: "Type something here",
                resolveReadyToConfirm: {
                    !$0.isEmpty
                },
                ctaTitle: "Add"
            )
        }
    }
    .padding()
    .frame(width: 480, height: 320)
    .background(StyleTheme.cocoa.colors.background1)
}
