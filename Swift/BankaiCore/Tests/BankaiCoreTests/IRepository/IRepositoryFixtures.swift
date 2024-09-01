//
//  IRepositoryFixtures.swift
//  
//
//  Created by Sergio Daniel on 1/09/24.
//

@testable import BankaiCore
import Foundation

struct TestObject: Traceable {
    let id: Int
    let name: String
    let updatedAt: Date?
}

struct TestFilter: Filter {
    var onlyLocally: Bool
}

class FixtureLocal: ILocal {
    typealias F = TestFilter
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
    
    func prepare() {}
    
    func store(_ items: [T]) async throws {
        print("Stored items: \(items)")
        try await self.storeFixture(items)
    }
    
    func retrieve(filter: TestFilter?) async throws -> [T] {
        return try await retrieveFixture()
    }
}

class FixtureRemote: IRemote {
    typealias F = TestFilter
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
    
    func prepare() {}
    
    func pull(filter: TestFilter?) async throws -> [T] {
        return try await self.pullFixture()
    }
    
    func push(_ items: [T]) async throws {
        print("Pushed items: \(items)")
        try await self.pushFixture(items)
    }
}
