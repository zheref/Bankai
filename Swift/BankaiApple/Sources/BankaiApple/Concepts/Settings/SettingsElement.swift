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
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(originalValue)
    }
    
    public static func == (lhs: AnySettingsElement,
                           rhs: AnySettingsElement) -> Bool {
        lhs.key == rhs.key
            && type(of: lhs.originalValue) == type(of: rhs.originalValue)
    }
    
    public static func group(_ key: String,
                             titled title: String,
                             with elements: [any SettingsElement]) -> AnySettingsElement {
        let r = SettingsGroup(key: key,
                              title: title,
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
    
    @available(macOS 12.0, *)
    public static func heading(_ key: String, titled title: String, icon: SymbolIcon? = nil) -> AnySettingsElement {
        let r = SettingsPreference.heading(
            PreferenceConfig(key: key, title: title, icon: icon)
        )
        return r.eraseToAnySettingsElement()
    }
    
    @available(macOS 12.0, *)
    public static func fixed(_ key: String, titled title: String, icon: SymbolIcon) -> AnySettingsElement {
        let r = SettingsPreference.fixed(
            PreferenceConfig(key: key, title: title, icon: icon)
        )
        return r.eraseToAnySettingsElement()
    }
    
    @available(macOS 12.0, *)
    public static func toggle(_ key: String, titled title: String, icon: SymbolIcon) -> AnySettingsElement {
        let r = SettingsPreference.toggle(
            PreferenceConfig(key: key, title: title, icon: icon)
        )
        return r.eraseToAnySettingsElement()
    }
    
    @available(macOS 12.0, *)
    public static func text(_ key: String, titled title: String, icon: SymbolIcon) -> AnySettingsElement {
        let r = SettingsPreference.text(
            PreferenceConfig(key: key, title: title, icon: icon)
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
    public let elements: [AnySettingsElement]
    public let presentationPreference: SettingsGroupPresentation
    
    public init(key: String,
                title: String?,
                elements: [AnySettingsElement],
                presentationPreference: SettingsGroupPresentation) {
        self.key = key
        self.title = title
        self.elements = elements
        self.presentationPreference = presentationPreference
    }
    
    public init(key: String,
                title: String?,
                elements: [any SettingsElement],
                presentationPreference: SettingsGroupPresentation) {
        self.init(key: key,
                  title: title,
                  elements: elements.map { $0.eraseToAnySettingsElement() },
                  presentationPreference: presentationPreference)
    }
}

public enum SettingsPreference: SettingsElement {
    case heading(PreferenceConfig)
    case fixed(PreferenceConfig)
    case text(PreferenceConfig)
    case toggle(PreferenceConfig)
    case picker(PreferenceConfig)
    
    public var key: String {
        switch self {
        case .heading(let config): return config.key
        case .fixed(let config): return config.key
        case .text(let config): return config.key
        case .toggle(let config): return config.key
        case .picker(let config): return config.key
        }
    }
    
    public var title: String? {
        switch self {
        case .heading(let config): return config.title
        case .fixed(let config): return config.title
        case .text(let config): return config.title
        case .toggle(let config): return config.title
        case .picker(let config): return config.title
        }
    }
}

public struct PreferenceConfig: Hashable {
    public let key: String
    public let title: String
    public let binding: Binding<String>
    public let description: String?
    public let icon: SymbolIcon?
    public let placeholder: String?
    
    
    public init(key: String, title: String, description: String? = nil, icon: SymbolIcon? = nil, placeholder: String? = nil, binding: Binding<String>? = nil) {
        self.key = key
        self.title = title
        self.description = description
        self.icon = icon
        self.placeholder = placeholder
        self.binding = binding ?? .constant("")
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(title)
    }
    
    public static func == (lhs: PreferenceConfig, rhs: PreferenceConfig) -> Bool {
        lhs.key == rhs.key && lhs.title == rhs.title
    }
}
