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
        if #available(macOS 13.0, *) {
            NavigationStack {
                render(elements: elements, theme: theme)
                .navigationDestination(for: SettingsGroup.self) { group in
                    render(elements: group.elements, theme: theme)
                }
            }
        } else {
            NavigationView {
                render(elements: elements, theme: theme)
            }
        }
    }
    
    @ViewBuilder
    public func render(elements: [AnySettingsElement], theme: StyleTheme = .cocoa) -> some View {
        ScrollView(showsIndicators: false) {
            HStack {
                Spacer()
                VStack(spacing: 30) {
                    Spacer(minLength: 10) // scrollVerticalInset
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
        } else if let placement = element.originalValue as? SettingsPlacement {
            renderHeading(for: placement)
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    public func render(group: SettingsGroup) -> some View {
        switch group.presentationPreference {
        case .preferOpenSection:
            VStack(spacing: 0) {
                ForEach(Array(group.elements.enumerated()), id: \.element) {
                    (offset, element) in
                    render(element: element)
                    if offset < (group.elements.count - 1) {
                        Divider()
                    }
                }
            }
            .frame(maxWidth: 800, minHeight: 40)
            .background(theme.colors.background2)
            .innerCapsule(theme: theme)
        case .preferNested:
            render(linkFor: group)
        }
        
    }
    
    @ViewBuilder
    public func render(preference: SettingsPreference) -> some View {
        HStack(alignment: .center) {
            if let icon = preference.icon {
                icon
            }
            Text(preference.title ?? "Untitled")
                .font(.system(size: 13))
            Spacer()
            switch preference {
            case .text(let config):
                TextField(config.placeholder ?? "Enter text", text: config.binding)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.trailing)
            case .toggle(let config):
                Toggle(isOn: config.binding) {
                    EmptyView()
                }
            default:
                EmptyView()
            }
        }
        .frame(minHeight: 30)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }
    
    @ViewBuilder
    public func render(linkFor group: SettingsGroup) -> some View {
        if #available(macOS 13.0, *) {
            NavigationLink(value: group, label: {
                HStack(alignment: .center) {
                    if let icon = group.icon {
                        icon
                    }
                    Text(group.title ?? "Untitled")
                        .font(.system(size: 13))
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            })
            .buttonStyle(.plain)
            .frame(minHeight: 30)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
        } else {
            NavigationLink {
                render(elements: group.elements, theme: theme)
            } label: {
                HStack(alignment: .center) {
                    if let icon = group.icon {
                        icon
                    }
                    Text(group.title ?? "Untitled")
                        .font(.system(size: 13))
                    Spacer()
                    Image(nsImage: NSImage(named: "chevron.right")!)
                }
            }
            .frame(minHeight: 30)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
        }
    }
    
    @ViewBuilder
    public func renderHeading(for placement: SettingsPlacement) -> some View {
        VStack(spacing: 3) {
            if let icon = placement.icon {
                icon
            }
            Text(placement.title ?? "Untitled")
                .font(.system(size: 24, weight: .bold))
            if let description = placement.description {
                if #available(macOS 13.0, *) {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.colors.foreground2)
                        .frame(maxWidth: 360)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                } else if #available(macOS 12.0, *) {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.colors.foreground2)
                        .frame(maxWidth: 360)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.foreground2)
                        .frame(maxWidth: 360)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(minHeight: 40)
        .padding(.horizontal, 10)
        .padding(.vertical, 16) // normally divided by 6, divided by 3 when large
    }
    
}

//@available(macOS 13.0, *)
//#Preview {
//    NavigationStack {
//        SettingsPage()
//    }
//    .frame(width: 640, height: 480)
//}
