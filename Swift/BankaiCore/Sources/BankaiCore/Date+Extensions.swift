//
//  Date+Extensions.swift
//  
//
//  Created by Sergio Daniel on 1/09/24.
//

import Foundation

extension Date {
    public var dateComponents: DateComponents {
        Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: self
        )
    }
    
    public static func fromDateComponents(year: UInt16, month: UInt8, day: UInt8) -> Date? {
        var components = DateComponents()

        components.year = Int(year)
        components.month = Int(month)
        components.day = Int(day)

        return Calendar.current.date(from: components)
    }

    public static func fromTimeComponents(hours: UInt8, minutes: UInt8, seconds: UInt8) -> Date? {
        var components = DateComponents()

        components.hour = Int(hours)
        components.minute = Int(minutes)
        components.second = Int(seconds)

        return Calendar.current.date(from: components)
    }

    public static func endOfDay(from referenceDate: Date = Date()) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: referenceDate)
        components.hour = 23
        components.minute = 59
        components.second = 59
        return Calendar.current.date(from: components)!
    }
    
    public static func businessStartOfDay(from referenceDate: Date) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: referenceDate)
        components.hour = 9
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)!
    }
    
    public static func startOfDay(from referenceDate: Date) -> Date {
        Calendar.current.startOfDay(for: referenceDate)
    }
    
    public func digitalTime(includingSeconds: Bool = false) -> String {
        let formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = includingSeconds ? "HH:mm:ss" : "HH:mm"
            return formatter
        }()
        return formatter.string(from: self)
    }
    
    public func removingTimeInterval(_ interval: TimeInterval) -> Date {
        .init(timeIntervalSince1970: self.timeIntervalSince1970 - interval)
    }
}

extension DateComponents {
    public var asDate: Date? {
        Calendar.current.date(from: self)
    }
}

extension TimeInterval {
    public func digitalDuration(includingSeconds: Bool = false) -> String {
        let totalSeconds = Int(self)
        var remainingSeconds = totalSeconds
        
        let hours = remainingSeconds / 3600
        remainingSeconds = remainingSeconds % 3600
        let minutes = remainingSeconds / 60
        remainingSeconds = remainingSeconds % 60
        let seconds = remainingSeconds
        
        if hours > 0 {
            if includingSeconds {
                return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%02d:%02d", hours, minutes)
            }
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
