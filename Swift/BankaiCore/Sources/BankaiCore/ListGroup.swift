//
//  ListGroup.swift
//  BankaiCore
//
//  Created by Sergio Daniel on 12/13/24.
//

import Foundation

public struct ListGroup<Element: Identifiable, Key: Printable> {
    public let key: Key
    
    public let elements: [Element]
    
    public init(key: Key, elements: [Element]) {
        self.key = key
        self.elements = elements
    }
    
    public var isEmpty: Bool { elements.isEmpty }
    
    public var count: Int { elements.count }
    
    public var groupName: String { key.printableDescription }
}
