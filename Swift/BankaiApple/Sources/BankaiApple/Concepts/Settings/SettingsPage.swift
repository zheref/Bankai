//
//  SettingsPage.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 4/03/25.
//

import SwiftUI

public struct SettingsPage: View {
    
    public let theme = StyleTheme.cocoa
    
    public var body: some View {
        Text("I'm settings")
    }
    
}

@available(macOS 13.0, *)
#Preview {
    NavigationStack {
        SettingsPage()
    }
    .frame(width: 640, height: 480)
}
