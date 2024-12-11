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
    
    // Initilializer
    public init(
        header: String? = nil,
        @ViewBuilder description: () -> Description,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header
        self.description = description()
        self.content = content()
    }
    
    // Render
    
    public var body: some View {
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
        .background(Color.white)
        .cornerRadius(10)
    }
    
}

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
