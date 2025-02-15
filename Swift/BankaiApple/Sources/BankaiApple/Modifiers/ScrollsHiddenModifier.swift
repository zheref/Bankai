//
//  ScrollsHiddenModifier.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 12/02/25.
//

import SwiftUI

extension ScrollView {
    
    @MainActor
    public func scrollsHidden(_ hidden: Bool = true) -> some View {
        #if os(macOS)
        if #available(macOS 13.0, *), OSEnv.isAtLeast(.ventura) {
            //self.scrollIndicators(.hidden) as! ScrollView<Content>
            self
        } else {
            self
        }
        #else
        self
        #endif
    }
    
}
