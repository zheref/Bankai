//
//  ColorHelpers.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 21/02/25.
//

import Foundation
import CoreGraphics

extension CGColor {
    
    /// Returns the hexadecimal string representation of the color.
    /// - Parameter includeAlpha: Whether to include the alpha channel in the hex string.
    /// - Returns: A string in the format "#RRGGBB" or "#RRGGBBAA", or nil if the color can’t be converted.
    public func hexString(includeAlpha: Bool = true) -> String? {
        // Convert the color to the sRGB color space.
        guard let sRGBColor = self.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!,
                                             intent: .defaultIntent,
                                             options: nil),
              let components = sRGBColor.components,
              components.count >= 3 else {
            return nil
        }
        
        // Extract RGB components.
        let red = components[0]
        let green = components[1]
        let blue = components[2]
        // Get alpha either from components (if available) or from the color's alpha property.
        let alpha: CGFloat = (components.count >= 4) ? components[3] : sRGBColor.alpha

        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X",
                          Int(red * 255),
                          Int(green * 255),
                          Int(blue * 255),
                          Int(alpha * 255))
        } else {
            return String(format: "#%02X%02X%02X",
                          Int(red * 255),
                          Int(green * 255),
                          Int(blue * 255))
        }
    }
    
    /// Creates a CGColor from a hexadecimal string.
    /// - Parameter hex: A string in the format "#RRGGBB" or "#RRGGBBAA" (the '#' is optional).
    /// - Returns: A CGColor instance if the string is valid; otherwise, nil.
    public static func fromHexString(_ hex: String) -> CGColor? {
        // Remove the '#' if present.
        let hexString: String
        if hex.hasPrefix("#") {
            hexString = String(hex.dropFirst())
        } else {
            hexString = hex
        }
        
        // The string should be 6 or 8 characters long.
        guard hexString.count == 6 || hexString.count == 8 else {
            return nil
        }
        
        // Convert the hex string to an integer.
        var rgbValue: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&rgbValue) else {
            return nil
        }
        
        let r, g, b, a: CGFloat
        if hexString.count == 6 {
            r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgbValue & 0x0000FF) / 255.0
            a = 1.0
        } else { // 8 characters
            r = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgbValue & 0x000000FF) / 255.0
        }
        
        // Create a CGColor in the sRGB color space.
        guard let sRGB = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }
        return CGColor(colorSpace: sRGB, components: [r, g, b, a])
    }
    
}
