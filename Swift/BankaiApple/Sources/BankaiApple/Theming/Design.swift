//
//  Design.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 4/03/25.
//

import SwiftUI

public struct DesignSizes {
    public let regularMajorPadding: CGFloat
    public let regularMaxListWidth: CGFloat
    public let regularSurroundingPadding: CGFloat
    public let textFieldHeight: CGFloat
    public let textFieldCornerRadius: CGFloat
}

public struct PaddingValues {
    public let big: CGFloat
    public let regular: CGFloat
    public let minimum: CGFloat
}

public protocol Design {
    var sizes: DesignSizes { get }
    var padding: PaddingValues { get }
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
                    regularMaxListWidth: 640,
                    regularSurroundingPadding: 13.0,
                    textFieldHeight: 40.0,
                    textFieldCornerRadius: 20.0
                )
        default:
                .init(
                    regularMajorPadding: 20.0,
                    regularMaxListWidth: 640,
                    regularSurroundingPadding: 13.0,
                    textFieldHeight: 40.0,
                    textFieldCornerRadius: 20.0
                )
        }
    }
    
    public var padding: PaddingValues {
        switch self {
        case .cocoa: // Cocoa Designs are more compact
            return .init(
                big: 20.0,
                regular: 13.0,
                minimum: 9.0
            )
        case .cupertino: // Cupertino Designs are more spacious
            return .init(
                big: 21.0,
                regular: 14.0,
                minimum: 10.0
            )
        default:
            return .init(
                big: 18.0,
                regular: 12.0,
                minimum: 8.0
            )
        }
    }
}
