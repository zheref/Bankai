//
//  SettingsPage.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 4/03/25.
//

import SwiftUI

public struct SettingsPage: View {
    
    public let elements: [AnySettingsElement]
    public let theme: StyleTheme
    
    public init(elements: [AnySettingsElement], theme: StyleTheme = .cocoa) {
        self.elements = elements
        self.theme = theme
    }
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            HStack {
                Spacer()
                VStack {
                    ForEach(elements) { element in
                        render(element: element)
                    }
                }
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    public func render(element: AnySettingsElement) -> some View {
        if let group = element.originalValue as? SettingsGroup {
            render(group: group)
        } else if let preference = element.originalValue as? SettingsPreference {
            render(preference: preference)
        }
    }
    
    @ViewBuilder
    public func render(group: SettingsGroup) -> some View {
        VStack(spacing: 0) {
            ForEach(group.elements) { element in
                render(element: element)
            }
        }
        .frame(maxWidth: 800, minHeight: 40)
        .innerCapsule()
    }
    
    @ViewBuilder
    public func render(preference: SettingsPreference) -> some View {
        HStack(alignment: .center) {
            Text(preference.title ?? "Untitled")
                .font(.system(size: 14))
            Spacer()
            switch preference {
            case .text(let config):
                TextField(config.placeholder ?? "Enter text", text: config.binding)
                    .textFieldStyle(.plain)
            default:
                EmptyView()
            }
        }
    }
    
}

//@available(macOS 13.0, *)
//#Preview {
//    NavigationStack {
//        SettingsPage()
//    }
//    .frame(width: 640, height: 480)
//}
