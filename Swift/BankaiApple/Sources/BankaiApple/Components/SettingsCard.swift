//
//  SettingsCard.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 12/11/24.
//

import SwiftUI

public struct SettingsCard<Description: View, Content: View>: View {
    
    // MARK: Stored Properties
    
    // Props
    let header: String?
    let description: Description
    let content: Content
    let theme: StyleTheme
    
    // Initilializer
    public init(
        header: String? = nil,
        theme: StyleTheme = .cocoa,
        @ViewBuilder description: () -> Description,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header
        self.description = description()
        self.content = content()
        self.theme = theme
    }
    
    // Render
    
    public var body: some View {
        #if os(macOS)
        HStack {
            VStack(alignment: .leading) {
                if let header {
                    Text(header)
                        .font(.custom("SFProDisplay-Medium", size: 14))
                        .padding(.bottom, 0.5)
                }
                description
            }
            Spacer()
            content
        }
        .padding(20)
        .background(theme.colors.background1)
        .cornerRadius(10)
        #else
        Section {
            HStack {
                VStack(alignment: .leading) {
                    if let header {
                        Text(header)
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.bottom, 0.5)
                    }
                    description
                }
                Spacer()
                content
            }
        }
        #endif
    }
    
}

#if os(macOS)
#Preview("A common settings card") {
    VStack {
        SettingsCard(header: "A Simple Header") {
            Text("You should probably tap the action on the right.")
        } content: {
            Button("Do this!") {}
        }
    }
    .frame(width: 600, height: 600)
    .padding()
}

#Preview("A settings card without a title") {
    VStack {
        SettingsCard() {
            Text("You should probably tap the action on the right.")
        } content: {
            Button("Do this!") {}
        }
    }
    .frame(width: 600, height: 600)
    .padding()
}
#else
#Preview("A common settings card") {
    List {
        SettingsCard(header: "A Simple Header") {
            Text("You should probably tap the action on the right.")
                .font(.caption)
        } content: {
            Button("Do this!") {}
                .buttonStyle(.borderedProminent)
        }
    }
    .background(StyleTheme.cocoa.colors.background1)
}
#endif
