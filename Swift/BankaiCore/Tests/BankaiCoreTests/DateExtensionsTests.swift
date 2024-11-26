//
//  DateExtensionsTests.swift
//  BankaiCore
//
//  Created by Sergio Daniel on 11/8/24.
//

import Foundation
import Testing
@testable import BankaiCore

struct DateExtensionsTests {

    @Test func testFromTimeComponents() async throws {
        let time = Date.fromTimeComponents(
            hours: 8,
            minutes: 15,
            seconds: 5
        )!
        
        let components = Calendar.current.dateComponents(
            [.hour, .minute, .second],
            from: time
        )
        
        #expect(components.hour == 8)
        #expect(components.minute == 15)
        #expect(components.second == 5)
    }
    
    @Test func testFromTimeComponents2() async throws {
        let time = Date.fromTimeComponents(
            hours: 8,
            minutes: 15,
            seconds: 5
        )!
        
        let hours = Calendar.current.component(.hour, from: time)
        let minutes = Calendar.current.component(.minute, from: time)
        let seconds = Calendar.current.component(.second, from: time)
        
        #expect(hours == 8)
        #expect(minutes == 15)
        #expect(seconds == 5)
    }

}
