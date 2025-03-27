//
//  SettingsElement.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 5/03/25.
//

import SwiftUI

public protocol SettingsElement: Hashable, Identifiable {
    var key: String { get }
    var title: String? { get }
    var icon: SymbolIcon? { get }
}

extension SettingsElement {
    public var id: String { key }
    
    public func eraseToAnySettingsElement() -> AnySettingsElement {
        .init(originalValue: self)
    }
}

public struct AnySettingsElement: SettingsElement {
    public var originalValue: any SettingsElement
    
    init(originalValue: any SettingsElement) {
        self.originalValue = originalValue
    }
    
    public var key: String { originalValue.key }
    public var title: String? { originalValue.title }
    public var icon: SymbolIcon? { originalValue.icon }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(originalValue)
    }
    
    public static func == (lhs: AnySettingsElement,
                           rhs: AnySettingsElement) -> Bool {
        lhs.key == rhs.key
    }
    
    public static func group(_ key: String,
                             titled title: String,
                             icon: SymbolIcon? = nil,
                             with elements: [AnySettingsElement]) -> AnySettingsElement {
        let r = SettingsGroup(key: key,
                              title: title,
                              icon: icon,
                              elements: elements,
                              presentationPreference: .preferNested)
        return r.eraseToAnySettingsElement()
    }
    
    public static func section(_ key: String,
                               titled title: String? = nil,
                               with elements: [AnySettingsElement] = []) -> AnySettingsElement {
        let r = SettingsGroup(key: key,
                              title: title,
                              elements: elements,
                              presentationPreference: .preferOpenSection)
        return r.eraseToAnySettingsElement()
    }
    
    public static func heading(_ key: String,
                               titled title: String,
                               description: String? = nil,
                               icon: SymbolIcon? = nil) -> AnySettingsElement {
        let r = SettingsPlacement(
            key: key,
            title: title,
            icon: icon,
            description: description,
            style: .heading
        )
        return r.eraseToAnySettingsElement()
    }
    
    @available(macOS 12.0, *)
    public static func fixed(_ key: String,
                             titled title: String,
                             icon: SymbolIcon) -> AnySettingsElement {
        let r = SettingsPlacement(
            key: key,
            title: title,
            icon: icon,
            style: .fixed
        )
        return r.eraseToAnySettingsElement()
    }
    
    public static func toggle(_ key: String,
                              titled title: String,
                              defaultValue: Bool = false,
                              icon: SymbolIcon) -> AnySettingsElement {
        let r = SettingsPreference.toggle(
            PreferenceConfig(
                key: key,
                title: title,
                defaultValue: defaultValue,
                icon: icon
            )
        )
        return r.eraseToAnySettingsElement()
    }
    
    @available(macOS 12.0, *)
    public static func text(_ key: String,
                            titled title: String,
                            defaultValue: String = "",
                            icon: SymbolIcon) -> AnySettingsElement {
        let r = SettingsPreference.text(
            PreferenceConfig(
                key: key,
                title: title,
                defaultValue: defaultValue,
                icon: icon
            )
        )
        return r.eraseToAnySettingsElement()
    }
}

public enum SettingsGroupPresentation {
    case preferOpenSection
    case preferNested
}

public struct SettingsGroup: SettingsElement {
    public let key: String
    public let title: String?
    public let icon: SymbolIcon?
    public let elements: [AnySettingsElement]
    public let presentationPreference: SettingsGroupPresentation
    
    public init(key: String,
                title: String?,
                icon: SymbolIcon? = nil,
                elements: [AnySettingsElement],
                presentationPreference: SettingsGroupPresentation) {
        self.key = key
        self.title = title
        self.icon = icon
        self.elements = elements
        self.presentationPreference = presentationPreference
    }
    
    public init(key: String,
                title: String?,
                icon: SymbolIcon? = nil,
                elements: [any SettingsElement],
                presentationPreference: SettingsGroupPresentation) {
        self.init(key: key,
                  title: title,
                  icon: icon,
                  elements: elements.map { $0.eraseToAnySettingsElement() },
                  presentationPreference: presentationPreference)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(title)
    }
    
    public static func == (lhs: SettingsGroup, rhs: SettingsGroup) -> Bool {
        lhs.key == rhs.key && lhs.title == rhs.title && lhs.elements == rhs.elements
    }
}

public struct SettingsPlacement: SettingsElement {
    public enum Style {
        case fixed
        case heading
    }
    
    public let key: String
    public let title: String?
    public let icon: SymbolIcon?
    public let description: String?
    public let style: Style
    
    public init(key: String, title: String?, icon: SymbolIcon?, description: String? = nil, style: Style = .fixed) {
        self.key = key
        self.title = title
        self.icon = icon
        self.description = description
        self.style = style
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(title)
        hasher.combine(style)
    }
    
    public static func == (lhs: SettingsPlacement, rhs: SettingsPlacement) -> Bool {
        lhs.key == rhs.key && lhs.title == rhs.title && lhs.style == rhs.style
    }
}

public enum SettingsPreference: SettingsElement {
    case text(PreferenceConfig<String>)
    case toggle(PreferenceConfig<Bool>)
    case picker(PreferenceConfig<String>)
    
    public var key: String {
        switch self {
        case .text(let config): return config.key
        case .toggle(let config): return config.key
        case .picker(let config): return config.key
        }
    }
    
    public var title: String? {
        switch self {
        case .text(let config): return config.title
        case .toggle(let config): return config.title
        case .picker(let config): return config.title
        }
    }
    
    public var icon: SymbolIcon? {
        switch self {
        case .text(let config): return config.icon
        case .toggle(let config): return config.icon
        case .picker(let config): return config.icon
        }
    }
}

public struct PreferenceConfig<T: Equatable>: Hashable {
    public let key: String
    public let title: String
    public let description: String?
    public let icon: SymbolIcon?
    public let placeholder: String?
    public let defaultValue: T
    
    
    public init(key: String, title: String, defaultValue: T, description: String? = nil, icon: SymbolIcon? = nil, placeholder: String? = nil) {
        self.key = key
        self.title = title
        self.defaultValue = defaultValue
        self.description = description
        self.icon = icon
        self.placeholder = placeholder
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(title)
    }
    
    public static func == (lhs: PreferenceConfig, rhs: PreferenceConfig) -> Bool {
        lhs.key == rhs.key && lhs.title == rhs.title
    }
}
