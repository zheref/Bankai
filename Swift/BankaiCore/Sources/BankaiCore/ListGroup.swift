//
//  ListGroup.swift
//  BankaiCore
//
//  Created by Sergio Daniel on 12/13/24.
//

import Foundation

public struct ListGroup<Element: Identifiable, Key: Printable>: Equatable, Hashable, Identifiable
    where Element: Equatable, Key: Equatable, Element: Hashable, Key: Hashable {
    
    /// The key that identifies this group uniquely
    public let key: Key
    
    /// The title preferred for display. Key printable description will be used if none is provided
    /// for display purposes
    public var title: String?
    
    /// The unique ID of the group. Resolved as the key as it is expected to be unique.
    public var id: Key { key }
    
    /// The elements held within this group
    public var elements: [Element]
    
    /// Whether there's more elements expected for this group
    public var isTrimmed: Bool
    
    public init(key: Key, elements: [Element], isTrimmed: Bool = false, title: String? = nil) {
        self.key = key
        self.elements = elements
        self.isTrimmed = isTrimmed
        self.title = title
    }
    
    public var isEmpty: Bool { elements.isEmpty }
    
    public var count: Int { elements.count }
    
    public var groupName: String { key.printableDescription }
    
    public subscript(index: Int) -> Element {
        get {
            elements[index]
        }
        set {
            elements[index] = newValue
        }
    }
    
    public mutating func append(_ element: Element) {
        elements.append(element)
    }
    
    public mutating func remove(at index: Int) -> Element {
        elements.remove(at: index)
    }
    
    public static func == (lhs: ListGroup, rhs: ListGroup) -> Bool {
        lhs.key == rhs.key && lhs.elements == rhs.elements
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(elements)
    }
    
    public var displayName: String { title ?? key.printableDescription }
}

extension String: Printable {
    public var printableDescription: String { self }
}
