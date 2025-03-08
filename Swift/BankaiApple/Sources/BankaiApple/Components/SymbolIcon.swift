//
//  SymbolIcon.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 8/03/25.
//

import SwiftUI

public struct SymbolIcon: View {
    public enum SymbolSize {
        case tiny
        case small
        case large
        case huge
        
        public var dimensions: CGSize {
            switch self {
            case .tiny:
                return CGSize(width: 12, height: 12)
            case .small:
                return CGSize(width: 16, height: 16)
            case .large:
                return CGSize(width: 24, height: 24)
            case .huge:
                return CGSize(width: 48, height: 48)
            }
        }
    }
    
    public let name: String
    public let iconColor: Color
    public let size: SymbolSize
    public let initialBackground: Color
    public let finalBackground: Color
    
    public init(name: String,
                iconColor: Color = .primary,
                size: SymbolSize = .small,
                initialBackground: Color = .clear,
                finalBackground: Color? = nil) {
        self.name = name
        self.iconColor = iconColor
        self.size = size
        self.initialBackground = initialBackground
        self.finalBackground = finalBackground ?? initialBackground
    }
    
    @ViewBuilder
    public func image(with name: String) -> some View {
        if #available(macOS 12.0, *) {
            Image(systemName: name)
                .resizable()
                .symbolRenderingMode(.monochrome)
                .frame(width: size.dimensions.width,
                       height: size.dimensions.height)
                .foregroundStyle(iconColor)
        } else if #available(macOS 11.0, *) {
            Image(systemName: name)
                .resizable()
                .renderingMode(.template)
                .frame(width: size.dimensions.width,
                       height: size.dimensions.height)
                .foregroundColor(iconColor)
        } else {
            #if os(macOS)
            Image(nsImage: NSImage(named: name)!)
                .resizable()
                .renderingMode(.template)
                .frame(width: size.dimensions.width,
                       height: size.dimensions.height)
                .foregroundColor(iconColor)
            #else
            Image(uiImage: UIImage(named: name)!)
                .resizable()
                .renderingMode(.template)
                .frame(width: size.dimensions.width,
                       height: size.dimensions.height)
                .foregroundColor(iconColor)
            #endif
        }
    }
    
    public var body: some View {
        image(with: name)
            .padding(size.dimensions.width / 5)
            .background(
                LinearGradient(
                    gradient: Gradient(
                        colors: [initialBackground, finalBackground]
                    ),
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
            )
            .clipShape(
                RoundedRectangle(cornerRadius: size.dimensions.width / 3)
            )
            // .frame(width: size.dimensions.width, height: size.dimensions.height)
    }
}
