//
//  NavigationHelpers.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 17/12/24.
//

import SwiftUI

public struct NavigationBindingModifier<Item: Sendable, Destination: View>: ViewModifier {
    
    let item: Binding<Item?>
    let destination: (Item) -> Destination
    
    public func body(content: Content) -> some View {
        NavigationLink(isActive: item.asBool()) {
            destination(item.wrappedValue!)
        } label: {
            content
        }
    }
    
}

extension View {
    
    public func navigationBinding<Item: Sendable, Destination: View>(
        _ item: Binding<Item?>,
        @ViewBuilder destination: @escaping (Item) -> Destination
    ) -> some View {
        modifier(NavigationBindingModifier(item: item, destination: destination))
    }
    
}

@available(iOS, introduced: 13, deprecated: 16)
@available(macOS, introduced: 10.15, deprecated: 13)
@available(tvOS, introduced: 13, deprecated: 16)
@available(watchOS, introduced: 6, deprecated: 9)
extension NavigationLink {
    
    public init<D, C: View>(
        item: Binding<D?>,
        onNavigate: @escaping (_ isActive: Bool) -> Void,
        @ViewBuilder destination: (D) -> C,
        @ViewBuilder label: () -> Label
    ) where Destination == C? {
        self.init(
            destination: item.wrappedValue.map(destination),
            isActive: Binding(
                get: { item.wrappedValue != nil },
                set: { isActive, transaction in
                    onNavigate(isActive)
                    if !isActive {
                        item.transaction(transaction).wrappedValue = nil
                    }
                }
            ),
            label: label
        )
    }
    
    public init<D, C: View>(
            item: Binding<D?>,
            @ViewBuilder destination: (D) -> C,
            @ViewBuilder label: () -> Label
        ) where Destination == C? {
            self.init(
                destination: item.wrappedValue.map(destination),
                isActive: Binding(
                    get: { item.wrappedValue != nil },
                    set: { isActive, transaction in
                        if !isActive {
                            item.transaction(transaction).wrappedValue = nil
                        }
                    }
                ),
                label: label
            )
        }
    
}
