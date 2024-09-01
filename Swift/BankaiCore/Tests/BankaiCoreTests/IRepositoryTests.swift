//
//  IRepositoryTests.swift
//  
//
//  Created by Sergio Daniel on 13/08/24.
//

import Foundation
import Testing
@testable import BankaiCore

class TestRepository: IRepository {
    typealias F = TestFilter
    typealias T = TestObject
    typealias Local = FixtureLocal
    typealias Remote = FixtureRemote
    
    var local: Local
    var remotes: [Remote] = []
    
    required init(local: Local) {
        self.local = local
    }
}

struct IRepositoryTests {
    
    
    @Test
    func testOnlyLocalFetch() {
        
    }
    
}
