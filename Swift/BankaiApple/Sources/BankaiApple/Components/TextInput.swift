//
//  TextInput.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 3/9/25.
//

import SwiftUI

@available(macOS 12.0, *)
public struct TextInput: View {
    
    @Binding var text: String
    var focusedField: FocusState<AnyHashable?>.Binding
    var focusedKey: AnyHashable?
    let icon: Image?
    let placeholder: String
    let onSubmit: () -> Void
    let resolveReadyToConfirm: () -> Bool
    let ctaTitle: String?
    let theme: StyleTheme
    
    public init(
        text: Binding<String>,
        focusedField: FocusState<AnyHashable?>.Binding,
        focusedKey: AnyHashable?,
        icon: Image? = nil,
        placeholder: String = "",
        onSubmit: @escaping () -> Void = { },
        resolveReadyToConfirm: @escaping () -> Bool = { true },
        ctaTitle: String? = nil,
        theme: StyleTheme = .cocoa
    ) {
        self._text = text
        self.focusedField = focusedField
        self.focusedKey = focusedKey
        self.icon = icon
        self.placeholder = placeholder
        self.onSubmit = onSubmit
        self.resolveReadyToConfirm = resolveReadyToConfirm
        self.ctaTitle = ctaTitle
        self.theme = theme
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
            
            if let ctaTitle, resolveReadyToConfirm() {
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
        .innerCapsule(
            isFocused: focusedField.wrappedValue == focusedKey,
            theme: theme
        )
    }
    
}

@available(macOS 14.0, *)
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
                    !text.isEmpty
                },
                ctaTitle: "Add"
            )
        }
    }
    .padding()
    .frame(width: 480, height: 320)
}
