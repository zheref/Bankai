//
//  OSVersions.swift
//  BankaiApple
//
//  Created by Sergio Daniel on 18/12/24.
//

public typealias VersionDecimal = Double

public enum OSVersion: Comparable, Sendable {
    #if os(macOS)
    // Without Support
    case bigSur
    // Starting Support
    case monterey
    case ventura
    case sonoma
    case sequoia
    #else
    // Without Support
    case v15
    case v16
    // Starting Support
    case v17
    case v18
    case v18p2
    case v18p3
    #endif
    
    #if os(macOS)
    public static let latest: OSVersion = .sequoia
    #else
    public static let latest: OSVersion = .v18p3
    #endif
    
    public var decimal: VersionDecimal {
        #if os(macOS)
        switch self {
        case .bigSur: return 11.7
        case .monterey: return 12.6
        case .ventura: return 13.7
        case .sonoma: return 14.7
        case .sequoia: return 15.1
        }
        #else
        switch self {
        case .v15: return 15.0
        case .v16: return 16.0
        case .v17: return 17.0
        case .v18: return 18.0
        case .v18p2: return 18.2
        case .v18p3: return 18.3
        }
        #endif
    }
    
    public static func from(decimal: VersionDecimal) -> OSVersion? {
        switch decimal {
        #if os(macOS)
        case 11: return .bigSur
        case 12: return .monterey
        case 13: return .ventura
        case 14: return .sonoma
        case 15: return .sequoia
        #else
        case 15: return .v15
        case 16: return .v16
        case 18: return .v18
        case 18.2: return .v18p2
        case 18.3: return .v18p3
        #endif
        default: return nil
        }
    }
    
    public static func from(string: String) -> OSVersion? {
        let semverPieces = string.split(separator: ".")
        
        guard semverPieces.count >= 2 else { return nil }
        
        let major = semverPieces.first!
        let minor = semverPieces[1]
        
        guard let decimal = VersionDecimal("\(major).\(minor)") else {
            return nil
        }
        
        return .from(decimal: decimal)
    }
    
    public static func < (lhs: OSVersion, rhs: OSVersion) -> Bool {
        lhs.decimal < rhs.decimal
    }
    
    public static func >= (lhs: OSVersion, rhs: OSVersion) -> Bool {
        lhs.decimal >= rhs.decimal
    }
}

public class OSEnv {
    public typealias VersionStringResolver = () -> String
    
    @MainActor private static var _current: OSEnv?
    
    @MainActor public static var current: OSEnv? {
        get { _current }
        set {
            _current = newValue
            print(
                "Current environment initialized as: \(String(describing: _current?.TargetVersion))"
            )
        }
    }
    
    @MainActor public static func prior(to expectedVersion: OSVersion) -> Bool {
        guard let current else { return false }
        return current.TargetVersion < expectedVersion
    }
    
    @MainActor public static func isAtLeast(_ expectedVersion: OSVersion) -> Bool {
        guard let current else { return true }
        return current.TargetVersion >= expectedVersion
    }
    
    /// Earliest version supported by Kro
    #if os(macOS)
    public static let lowestSupported: OSVersion = .monterey
    #else
    public static let lowestSupported: OSVersion = .v17
    #endif
    
    /// Latest version supported by Kro
    #if os(macOS)
    public static let latestSupported: OSVersion = .sequoia
    #else
    public static let latestSupported: OSVersion = .v18p2
    #endif
    
    private var enforced: OSVersion?
    private var versionResolver: VersionStringResolver?
    
    /// An initializers, passing in a way to resolve the current platform
    /// version and possibly an enforced version of the OS to target
    public init(enforcing enforced: OSVersion? = nil,
                versionResolver: VersionStringResolver?) {
        self.enforced = enforced
        self.versionResolver = versionResolver
    }
    
    /// Resolves as a Double the current version of the operating system where
    /// the app is running.
    public var CurrentVersion: OSVersion? {
        guard let versionResolver else {
            return nil
        }
        
        let versionString = versionResolver()
        return .from(string: versionString)
    }
    
    /// Virtual target version at compile time. If enforced is not set,
    /// it will resolve to latest version supported by Kro.
    /// See and/or override "Latest".
    public var TargetVersion: OSVersion { enforced ?? Self.latestSupported }
    
    
}
