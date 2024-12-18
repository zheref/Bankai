//
//  OSVersions.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 18/12/24.
//

public typealias VersionDecimal = Double

public class OSVersion {
    public typealias VersionResolver = () -> String
    
    private static func versionDecimal(from str: String) -> VersionDecimal? {
        let semverPieces = str.split(separator: ".")
        
        guard semverPieces.count >= 2 else { return nil }
        
        let majorVersion = semverPieces.first!
        let minorVersion = semverPieces[1]
        return VersionDecimal("\(majorVersion).\(minorVersion)")
    }
    
    #if os(macOS)
    // Without Support
    public static let BigSur = 11.7
    
    // Starting Support
    public static let Monterey: VersionDecimal = 12.6
    public static let Ventura: VersionDecimal = 13.7
    public static let Sonoma: VersionDecimal = 14.7
    public static let Sequoia: VersionDecimal = 15.1
    #elseif os(iOS) // iOS and IPadOS
    // Without Support
    public static let OS_15: VersionDecimal = 15.0
    public static let OS_16: VersionDecimal = 16.0
    
    // Starting Support
    public static let OS_17: VersionDecimal = 17.0
    public static let OS_18: VersionDecimal = 18.0
    #elseif targetEnvironment(macCatalyst)
    // Without Support
    public static let SDK_16: VersionDecimal = 16.0
    
    // Starting Support
    public static let SDK_17: VersionDecimal = 17.0
    public static let SDK_18: VersionDecimal = 18.0
    #endif
    
    public static var Latest: VersionDecimal { Sequoia }
    
    private var enforced: VersionDecimal?
    private var versionResolver: VersionResolver?
    
    /// An initializers, passing in a way to resolve the current platform
    /// version and possibly an enforced version of the OS to target
    public init(enforced: Double? = nil, versionResolver: VersionResolver?) {
        self.enforced = enforced
        self.versionResolver = versionResolver
    }
    
    /// Resolves as a Double the current version of the operating system where
    /// the app is running.
    public var Current: VersionDecimal? {
        guard let versionResolver else {
            return nil
        }
        
        let versionString = versionResolver()
        return Self.versionDecimal(from: versionString)
    }
    
    /// Virtual target version at compile time. If enforced is not set,
    /// it will resolve to latest version supported by Kro.
    /// See and/or override "Latest".
    public var Target: VersionDecimal? { enforced ?? Self.Latest }
    
    
}
