//
//  TitleDesignModifier.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 15/02/25.
//

import SwiftUI

struct TitleDesignModifier: ViewModifier {
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
}

extension View {
    public func titleDesign() -> some View {
        modifier(TitleDesignModifier())
    }
}
