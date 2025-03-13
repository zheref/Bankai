//
//  SettingsPage.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 4/03/25.
//

import SwiftUI

public struct SettingsPage: View {
    
    public let elements: [AnySettingsElement]
    public let onPreferenceChanged: (SettingsPreference) -> Void
    public let readPreferenceValue: (SettingsPreference) -> Any?
    public let theme: StyleTheme
    public let os: OSEnv
    
    @State private var navigatedElement: AnySettingsElement?
    
    public init(
        elements: [AnySettingsElement],
        onPreferenceChanged: @escaping (SettingsPreference) -> Void,
        readPreferenceValue: @escaping (SettingsPreference) -> Any?,
        theme: StyleTheme = .cocoa,
        os: OSEnv? = nil
    ) {
        self.elements = elements
        self.onPreferenceChanged = onPreferenceChanged
        self.readPreferenceValue = readPreferenceValue
        self.theme = theme
        self.os = os ?? .latestAvailable
    }
    
    public func isActive(_ evaluated: any SettingsElement) -> Binding<Bool> {
        .init(
            get: { navigatedElement == evaluated.eraseToAnySettingsElement() },
            set: {
                if $0 {
                    navigatedElement = evaluated.eraseToAnySettingsElement()
                }
            }
        )
    }
    
    public func isSelected(_ evaluated: any SettingsElement) -> Bool {
        navigatedElement == evaluated.eraseToAnySettingsElement()
    }
    
    #if os(macOS)
    public var body: some View {
        if #available(macOS 13.0, *), os.isAtLeast(.ventura) {
            NavigationStack {
                render(elements: elements, theme: theme)
                .navigationDestination(for: SettingsGroup.self) { group in
                    render(elements: group.elements, theme: theme)
                        .navigationTitle(group.title ?? "")
                }
            }
            .frame(maxWidth: .infinity)
            .background(theme.colors.background1)
        } else {
            NavigationView {
                render(elements: elements, theme: theme)
                    .frame(minWidth: 480)
                    .frame(width: 640)
                    .frame(maxWidth: 800)
                    .background(theme.colors.background1)
            }
        }
    }
    #else
    public var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                render(elements: elements, theme: theme)
                .navigationDestination(for: SettingsGroup.self) { group in
                    render(elements: group.elements, theme: theme)
                        .navigationTitle(group.title ?? "")
                }
            }
            .frame(maxWidth: .infinity)
            .background(theme.colors.background1)
        } else {
            NavigationView {
                render(elements: elements, theme: theme)
            }
            .navigationViewStyle(.stack)
            .frame(maxWidth: .infinity)
            .background(theme.colors.background1)
        }
    }
    #endif
    
    @ViewBuilder
    public func render(elements: [AnySettingsElement],
                       theme: StyleTheme = .cocoa) -> some View {
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
            .padding(.horizontal, theme.design.sizes.minimumHorizontalPadding)
            .frame(maxWidth: theme.design.sizes.regularMaxListWidth)
        }
        .background(theme.colors.background1)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    public func render(element: AnySettingsElement, isInsideSection: Bool = false) -> some View {
        if let group = element.originalValue as? SettingsGroup {
            render(group: group)
        } else if let preference
                    = element.originalValue as? SettingsPreference {
            render(preference: preference)
        } else if let placement
                    = element.originalValue as? SettingsPlacement {
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
                    render(element: element, isInsideSection: true)
                    if offset < (group.elements.count - 1) {
                        Divider()
                            .background(theme.colors.border1)
                    }
                }
            }
            .frame(maxWidth: 800, minHeight: 40)
            .bankaiCapsule(theme: theme)
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
                TextField(config.placeholder ?? "Enter text",
                          text: config.binding)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.trailing)
            case .toggle(let config):
                Toggle(isOn: config.binding) {
                    EmptyView()
                }
                .toggleStyle(.switch)
            default:
                EmptyView()
            }
        }
        .frame(minHeight: 30)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(theme.colors.background2)
    }
    
    #if os(macOS)
    @ViewBuilder
    public func render(linkFor group: SettingsGroup) -> some View {
        if #available(macOS 13.0, *), os.isAtLeast(.ventura) {
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
                .frame(minHeight: 30)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    isSelected(group) ?
                        theme.colors.background3 : theme.colors.background2
                )
            })
            .buttonStyle(.plain)
        } else if #available(macOS 11.0, *), os.isAtLeast(.bigSur) {
            NavigationLink(isActive: isActive(group)) {
                render(elements: group.elements, theme: theme)
                    .navigationSubtitle(group.title ?? "")
            } label: {
                HStack(alignment: .center) {
                    if let icon = group.icon {
                        icon
                    }
                    Text(group.title ?? "Untitled")
                        .font(.system(size: 13))
                    Spacer()
                    Image(
                        nsImage: NSImage(
                            named: NSImage.rightFacingTriangleTemplateName
                        )!
                    )
                }
                .frame(minHeight: 30)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    isSelected(group) ?
                        theme.colors.background3 : theme.colors.background2
                )
            }
            .buttonStyle(.plain)
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
                    Image(
                        nsImage: NSImage(
                            named: NSImage.rightFacingTriangleTemplateName
                        )!
                    )
                }
            }
            .frame(minHeight: 30)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
        }
    }
    #else
    @ViewBuilder
    public func render(linkFor group: SettingsGroup) -> some View {
        if #available(iOS 16.0, *), os.isAtLeast(.v16) {
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
            NavigationLink(isActive: isActive(group)) {
                render(elements: group.elements, theme: theme)
            } label: {
                HStack(alignment: .center) {
                    if let icon = group.icon {
                        icon
                    }
                    Text(group.title ?? "Untitled")
                        .font(.system(size: 13))
                    Spacer()
                    Image(
                        uiImage: UIImage(systemName: "chevron.right")!
                    )
                }
            }
            .buttonStyle(.plain)
            .frame(minHeight: 30)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
        }
    }
    #endif
    
    #if os(macOS)
    @ViewBuilder
    public func renderHeading(for placement: SettingsPlacement) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 3) {
                if let icon = placement.icon {
                    icon
                }
                Text(placement.title ?? "Untitled")
                    .font(.system(size: 24, weight: .bold))
                if let description = placement.description {
                    if #available(macOS 13.0, *), os.isAtLeast(.ventura) {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundStyle(theme.colors.foreground2)
                            .frame(maxWidth: 360)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if #available(macOS 12.0, *), os.isAtLeast(.monterey) {
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
            Spacer()
        }
        .frame(minHeight: 40)
        .padding(.horizontal, 10)
        .padding(.vertical, 16) // normally divided by 6, by 3 when large
        .background(theme.colors.background2)
    }
    #else
    public func renderHeading(for placement: SettingsPlacement) -> some View {
        VStack(spacing: 3) {
            if let icon = placement.icon {
                icon
            }
            Text(placement.title ?? "Untitled")
                .font(.system(size: 24, weight: .bold))
            if let description = placement.description {
                if #available(iOS 16.0, *), os.isAtLeast(.v16) {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.colors.foreground2)
                        .frame(maxWidth: 360)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.colors.foreground2)
                        .frame(maxWidth: 360)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
        }
        .frame(minHeight: 40)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 16) // normally divided by 6, divided by 3 when large
    }
    #endif
    
}

@available(macOS 13.0, *)
#Preview {
    NavigationStack {
        SettingsPage(
            elements: [
                .section("default", titled: "Random", with: [
                    .toggle("some-setting",
                            titled: "Some Setting",
                            icon: .init(name: "gear"))
                ])
            ],
            onPreferenceChanged: { _ in },
            readPreferenceValue: { _ in nil }
        )
    }
    .frame(width: 640, height: 480)
}
