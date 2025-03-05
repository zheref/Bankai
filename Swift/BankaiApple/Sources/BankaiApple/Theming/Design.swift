//
//  Design.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 4/03/25.
//

import SwiftUI

public struct DesignSizes {
    public let regularMajorPadding: CGFloat
    public let regularSurroundingPadding: CGFloat
    public let textFieldHeight: CGFloat
    public let textFieldCornerRadius: CGFloat
}

public protocol Design {
    var sizes: DesignSizes { get }
}

public enum DesignLanguage: Design {
    case cocoa
    case cupertino
    case material2
    case material3
    case modern
    case fluent
    
    public var sizes: DesignSizes {
        switch self {
        case .cocoa:
                .init(
                    regularMajorPadding: 20.0,
                    regularSurroundingPadding: 13.0,
                    textFieldHeight: 40.0,
                    textFieldCornerRadius: 20.0
                )
        default:
                .init(
                    regularMajorPadding: 20.0,
                    regularSurroundingPadding: 13.0,
                    textFieldHeight: 40.0,
                    textFieldCornerRadius: 20.0
                )
        }
    }
}
