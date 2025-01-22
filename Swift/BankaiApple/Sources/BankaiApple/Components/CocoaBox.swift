//
//  CocoaBox.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 21/01/25.
//

import SwiftUI

public struct CocoaBox<Content: View>: View {
    
    let content: () -> Content
    
    public var body: some View {
        VStack {
            content()
        }
    }
    
}

#Preview {
    VStack {
        CocoaBox {
            Text("Some Content")
        }
    }
    #if os(macOS)
        .frame(width: 480, height: 300)
    #endif
}
