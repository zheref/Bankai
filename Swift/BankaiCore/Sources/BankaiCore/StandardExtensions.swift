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
        try await Task.sleep(nanoseconds: seconds.toNanoSeconds)
    }
}

extension Int {
    public var years: TimeInterval {
        Double(self) * 365.days
    }
    
    public var months: TimeInterval {
        Double(self) * 30.days
    }
    
    public var weeks: TimeInterval {
        Double(self) * 7.days
    }

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

extension Calendar.Component {
    func localizedString(pluralized: Bool = false) -> String {
        switch self {
        case .year:
            return pluralized ? "years" : "year"
        case .month:
            return pluralized ? "months" : "month"
        case .weekOfMonth, .weekOfYear:
            return pluralized ? "weeks" : "week"
        case .day:
            return pluralized ? "days" : "day"
        case .hour:
            return pluralized ? "hours" : "hour"
        case .minute:
            return pluralized ? "minutes" : "minute"
        case .second:
            return pluralized ? "seconds" : "second"
        case .nanosecond:
            return pluralized ? "nanoseconds" : "nanosecond"
        default:
            return "\(self)"
        }
    }
}

extension TimeInterval {
    public var toYears: Double {
        self / 1.years
    }
    
    public var toMonths: Double {
        self / 1.months
    }
    
    public var toWeeks: Double {
        self / 1.weeks
    }
    
    public var toDays: Double {
        self / 1.days
    }
    
    public var toHours: Double {
        self / 1.hours
    }
    
    public var toMinutes: Double {
        self / 1.minutes
    }
    
    public var toNanoSeconds: UInt64 {
        UInt64(self * 1_000_000_000)
    }
    
    public func converted(to unit: Calendar.Component) -> UInt64? {
        switch unit {
        case .year:
            return UInt64(self.toYears.rounded(.down))
        case .month:
            return UInt64(self.toMonths.rounded(.down))
        case .weekOfMonth, .weekOfYear:
            return UInt64(self.toWeeks.rounded(.down))
        case .day:
            return UInt64(self.toDays.rounded(.down))
        case .hour:
            return UInt64(self.toHours.rounded(.down))
        case .minute:
            return UInt64(self.toMinutes.rounded(.down))
        case .second:
            return UInt64(self)
        case .nanosecond:
            return self.toNanoSeconds
        default:
            return nil
        }
    }
    
    public func readable(preferring unit: Calendar.Component? = nil) -> String? {
        if let unit {
            if let converted = self.converted(to: unit) {
                return "\(converted) \(unit.localizedString(pluralized: converted > 1))"
            }
            
            return nil
        }
        
        if self < 60 {
            let seconds = Int(self.rounded(.down))
            return "\(seconds) \(Calendar.Component.second.localizedString(pluralized: seconds > 1))"
        } else if self.toMinutes < 60 {
            let minutes = Int(self.toMinutes.rounded(.down))
            return "\(minutes) \(Calendar.Component.minute.localizedString(pluralized: minutes > 1))"
        } else if self.toHours < 24 {
            let hours = Int(self.toHours.rounded(.down))
            return "\(hours) \(Calendar.Component.hour.localizedString(pluralized: hours > 1))"
        } else if self.toDays < 7 {
            let days = Int(self.toDays.rounded(.down))
            return "\(days) \(Calendar.Component.day.localizedString(pluralized: days > 1))"
        } else if self.toWeeks < 4 {
            let weeks = Int(self.toWeeks.rounded(.down))
            return "\(weeks) \(Calendar.Component.weekOfYear.localizedString(pluralized: weeks > 1))"
        } else if self.toMonths < 12 {
            let months = Int(self.toMonths.rounded(.down))
            return "\(months) \(Calendar.Component.month.localizedString(pluralized: months > 1))"
        } else {
            let years = Int(self.toYears.rounded(.down))
            return "\(years) \(Calendar.Component.year.localizedString(pluralized: years > 1))"
        }
    }
}

extension Date {
    public var oneDayOut: Date {
        self.addingTimeInterval(24.hours)
    }
}

extension String {
    public static var randomUUID: String {
        UUID().uuidString
    }
}
