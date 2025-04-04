//
//  FeatureFlags.swift
//  BankaiCore
//
//  Created by Sergio Daniel on 5/02/25.
//

public enum FeatureFlagState: Codable {
    case enabled
    case disabled
    case undetermined
}

public struct FeatureFlag: Codable, Hashable {
    let name: String
    
    public init(name: String) {
        self.name = name
    }
}

public struct FeatureFlagAssignment: Codable, Hashable {
    public let flag: FeatureFlag
    public var state: FeatureFlagState
    
    public init(flag: FeatureFlag, state: FeatureFlagState) {
        self.flag = flag
        self.state = state
    }
}

public protocol FeatureFlagService {
    func enabledResolver(_ featureFlag: FeatureFlag) -> () -> Bool
    func state(for featureFlag: FeatureFlag) -> FeatureFlagState?
    mutating func change(ff featureFlag: FeatureFlag, to state: FeatureFlagState)
}
