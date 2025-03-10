//
//  ReturnPressResolution.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 3/9/25.
//


//
//  OnReturnPressModifier.swift
//  Kro
//
//  Created by Sergio Daniel on 12/15/24.
//

import SwiftUI

public enum ReturnPressResolution { case handled, ignored }

@available(macOS 12.0, *)
public struct OnReturnPressModifier: ViewModifier {
    
    let action: () -> ReturnPressResolution
    
    public func body(content: Content) -> some View {
        #if os(macOS)
        if #available(macOS 14.0, *), OSEnv.isAtLeast(.sonoma) {
            content
                .focusable()
                .onKeyPress(.return) {
                    switch action() {
                    case .handled:
                        return .handled
                    case .ignored:
                        return .ignored
                    }
                }
        } else {
            content
                .focusable()
                .onSubmit {
                    _ = action()
                }
        }
        #else
        content
            .focusable()
            .onKeyPress(.return) {
                switch action() {
                case .handled:
                    return .handled
                case .ignored:
                    return .ignored
                }
            }
        #endif
    }
    
}

@available(macOS 12.0, *)
extension View {
    
    public func onReturnPress(perform action: @escaping () -> ReturnPressResolution) -> some View {
        modifier(OnReturnPressModifier(action: action))
    }
    
}
