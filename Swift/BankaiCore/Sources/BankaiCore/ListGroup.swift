//
//  ListGroup.swift
//  BankaiCore
//
//  Created by Sergio Daniel on 12/13/24.
//

import Foundation

public struct ListGroup<Element: Identifiable, Key: Printable>: Equatable, Hashable, Identifiable
    where Element: Equatable, Key: Equatable, Element: Hashable, Key: Hashable {
    
    public let key: Key
    
    public var title: String?
    
    public var id: Key { key }
    
    public var elements: [Element]
    
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
