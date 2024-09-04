//
//  StandardExtensions.swift
//  
//
//  Created by Sergio Daniel on 2/09/24.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    /// Has the current concurrent thread sleep for [seconds]
    /// seconds.
    /// - Parameters:
    ///     - for: Number of seconds to have thread sleep.
    static func sleep(for seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: seconds.asNanoSeconds)
    }
}

extension Int {

    public var days: TimeInterval {
        Double(self) * 24.hours
    }
    
    public var hours: TimeInterval {
        Double(self) * 60.minutes
    }
    
    public var minutes: TimeInterval {
        Double(self) * 60.seconds
    }
    
    public var seconds: TimeInterval {
        TimeInterval(self)
    }
}

extension TimeInterval {
    var asNanoSeconds: UInt64 {
        UInt64(self * 1_000_000_000)
    }
}

extension Date {
    public var oneDayOut: Date {
        self.addingTimeInterval(24.hours)
    }
}
