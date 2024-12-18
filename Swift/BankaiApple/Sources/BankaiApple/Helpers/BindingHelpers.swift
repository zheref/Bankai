//
//  BindingHelpers.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 17/12/24.
//

import SwiftUI

extension Binding where Value == Bool {
    
    public init<Wrapped: Sendable>(evaluatingOptional: Binding<Wrapped?>) {
        self.init(
            get: { evaluatingOptional.wrappedValue != nil },
            set: { if $0 == false { evaluatingOptional.wrappedValue = nil } }
        )
    }
    
}

extension Binding {
    
    public func asBool<Wrapped: Sendable>() -> Binding<Bool> where Value == Wrapped? {
        Binding<Bool>(evaluatingOptional: self)
    }
    
}
