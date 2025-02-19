//
//  TitleDesignModifier.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 15/02/25.
//

import SwiftUI

struct TitleDesignModifier: ViewModifier {
    #if os(macOS)
    func body(content: Content) -> some View {
        if #available(macOS 13.0, *) {
            content
                .font(.largeTitle)
                .bold()
                .fontDesign(.rounded)
        } else {
            content
                .font(.largeTitle)
                .font(.system(size: 30, weight: .bold, design: .rounded))
        }
    }
    #else
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .font(.largeTitle)
                .bold()
        } else if #available(iOS 16.1, *) {
            content
                .font(.largeTitle)
                .bold()
                .fontDesign(.rounded)
        } else {
            content
                .font(.largeTitle)
                .font(.system(size: 30, weight: .bold, design: .rounded))
        }
    }
    #endif
}

extension View {
    public func titleDesign() -> some View {
        modifier(TitleDesignModifier())
    }
}
