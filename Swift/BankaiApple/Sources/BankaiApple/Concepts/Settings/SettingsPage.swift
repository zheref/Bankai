//
//  SettingsPage.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 4/03/25.
//

import SwiftUI

public struct SymbolIcon: View {
    public enum SymbolSize {
        case tiny
        case small
        case large
        case huge
        
        public var dimensions: CGSize {
            switch self {
            case .tiny:
                return CGSize(width: 12, height: 12)
            case .small:
                return CGSize(width: 16, height: 16)
            case .large:
                return CGSize(width: 24, height: 24)
            case .huge:
                return CGSize(width: 32, height: 32)
            }
        }
    }
    
    public let name: String
    public let iconColor: Color
    public let size: SymbolSize
    public let initialBackground: Color
    public let finalBackground: Color
    
    public init(name: String,
                iconColor: Color = .primary,
                size: SymbolSize = .small,
                initialBackground: Color = .clear,
                finalBackground: Color? = nil) {
        self.name = name
        self.iconColor = iconColor
        self.size = size
        self.initialBackground = initialBackground
        self.finalBackground = finalBackground ?? initialBackground
    }
    
    @ViewBuilder
    public func image(with name: String) -> some View {
        if #available(macOS 12.0, *) {
            Image(systemName: name)
                .resizable()
                .symbolRenderingMode(.monochrome)
                .frame(width: size.dimensions.width,
                       height: size.dimensions.height)
                .foregroundStyle(iconColor)
        } else if #available(macOS 11.0, *) {
            Image(systemName: name)
                .resizable()
                .renderingMode(.template)
                .frame(width: size.dimensions.width,
                       height: size.dimensions.height)
                .foregroundColor(iconColor)
        } else {
            #if os(macOS)
            Image(nsImage: NSImage(named: name)!)
                .resizable()
                .renderingMode(.template)
                .frame(width: size.dimensions.width,
                       height: size.dimensions.height)
                .foregroundColor(iconColor)
            #else
            Image(uiImage: UIImage(named: name)!)
                .resizable()
                .renderingMode(.template)
                .frame(width: size.dimensions.width,
                       height: size.dimensions.height)
                .foregroundColor(iconColor)
            #endif
        }
    }
    
    public var body: some View {
        image(with: name)
            .frame(width: 20, height: 20)
    }
}

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
                Divider()
            }
        }
        .frame(maxWidth: 800, minHeight: 40)
        .background(theme.colors.background2)
        .innerCapsule(theme: theme)
    }
    
    @ViewBuilder
    public func render(preference: SettingsPreference) -> some View {
        if case .heading(let config) = preference {
            renderHeading(with: config)
        } else {
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
            .frame(height: 40)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
        }
    }
    
    @ViewBuilder
    public func renderHeading(with config: PreferenceConfig) -> some View {
        VStack {
            if let icon = config.icon {
                icon
            }
            Text(config.title)
        }
        .frame(height: 40)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }
    
}

//@available(macOS 13.0, *)
//#Preview {
//    NavigationStack {
//        SettingsPage()
//    }
//    .frame(width: 640, height: 480)
//}
