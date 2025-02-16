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

extension Array {
    public func first(_ n: Int) -> Array<Element> {
        guard n > 0 else { return [] }
        return count >= n ? Array(self[0..<n]) : self
    }
}

extension Array where Element: Comparable {
    
    public func bisect(given: (Element) -> Bool) -> (matching: [Element], nonMatching: [Element]) {
        var matching: [Element] = []
        var nonMatching: [Element] = []
        for element in self {
            if given(element) {
                matching.append(element)
            } else {
                nonMatching.append(element)
            }
        }
        return (matching, nonMatching)
    }
    
}
