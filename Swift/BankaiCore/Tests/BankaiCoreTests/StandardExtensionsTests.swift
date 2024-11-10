//
//  StandardExtensionsTests.swift
//  BankaiCore
//
//  Created by Sergio Daniel on 4/11/24.
//

import Testing

@Test("Readable Time Interval")
func readable() {
    #expect(1.minutes.readable() == "1 minute")
    #expect(10.minutes.readable() == "10 minutes")
    #expect(1.hours.readable() == "1 hour")
    #expect(10.hours.readable() == "10 hours")
    #expect(1.days.readable() == "1 day")
    #expect(30.days.readable() == "1 month")
    #expect(1.weeks.readable() == "1 week")
    #expect(20.weeks.readable() == "4 months")
}
