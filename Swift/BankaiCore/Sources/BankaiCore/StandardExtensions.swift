//
//  StandardExtensions.swift
//  
//
//  Created by Sergio Daniel on 2/09/24.
//

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
