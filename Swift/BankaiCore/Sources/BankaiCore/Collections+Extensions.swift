//
//  Collections+Extensions.swift
//  BankaiCore
//
//  Created by Sergio Daniel on 9/19/24.
//

extension Collection {
    // Returns the element at the specified index if it is within bounds, otherwise nil.
    public subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
