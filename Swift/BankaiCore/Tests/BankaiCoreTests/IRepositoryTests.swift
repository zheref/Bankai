//
//  IRepositoryTests.swift
//  
//
//  Created by Sergio Daniel on 13/08/24.
//

import Foundation
import Testing
@testable import BankaiCore

struct TestObject: Traceable {
    let id: Int
    let name: String
    let modifiedAt: Date
}

class FixtureLocal: ILocal {
    typealias T = TestObject
    
    var storeFixture: (_ items: [T]) async throws -> Void
    var retrieveFixture: () async throws -> [T]
    
    init(
        storeFixture: @escaping (_ items: [T]) async throws -> Void,
        retrieveFixture: @escaping () async throws -> [T]
    ) {
        self.storeFixture = storeFixture
        self.retrieveFixture = retrieveFixture
    }
    
    func store(_ items: [T]) async throws {
        print("Stored items: \(items)")
        try await self.storeFixture(items)
    }
    
    func retrieve() async throws -> [T] {
        return try await retrieveFixture()
    }
}

class FixtureRemote: IRemote {
    typealias T = TestObject
    
    static var name = "test-remote"
    
    var pushFixture: (_ items: [T]) async throws -> Void
    var pullFixture: () async throws -> [T]
    
    init(
        pushFixture: @escaping (_ items: [T]) async throws -> Void,
        pullFixture: @escaping () async throws -> [T]
    ) {
        self.pushFixture = pushFixture
        self.pullFixture = pullFixture
    }
    
    func pull() async throws -> [T] {
        return try await self.pullFixture()
    }
    
    func push(_ items: [T]) async throws {
        print("Pushed items: \(items)")
        try await self.pushFixture(items)
    }
}

class TestRepository: IRepository {
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
    func testSomething() {
        
    }
    
}
