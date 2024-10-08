//
//  IRepositoryFixtures.swift
//  
//
//  Created by Sergio Daniel on 1/09/24.
//

@testable import BankaiCore
import Foundation

struct TestObject: Traceable, Equatable {
    let id: Int
    let name: String
    let updatedAt: Date?
}

struct TestFilter: Filter {
    var onlyLocally: Bool
    var keywords: String?
}

class FixtureLocal: LocalDataSource {
    typealias F = TestFilter
    typealias T = TestObject
    
    var storeFixture: (_ items: [T]) async throws -> Void
    var retrieveFixture: (F?) async throws -> [T]
    
    init(
        storeFixture: @escaping (_ items: [T]) async throws -> Void,
        retrieveFixture: @escaping (F?) async throws -> [T]
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
        return try await retrieveFixture(filter)
    }
}

class FixtureRemote: RemoteDataSource {
    typealias F = TestFilter
    typealias T = TestObject
    
    static var name = "test-remote"
    
    var label: String
    
    var pushFixture: (_ items: [T]) async throws -> Void
    var pullFixture: (_ filter: FilterType?) async throws -> [T]
    
    init(
        label: String,
        pushFixture: @escaping (_ items: [T]) async throws -> Void,
        pullFixture: @escaping (_ filter: FilterType?) async throws -> [T]
    ) {
        self.label = label
        self.pushFixture = pushFixture
        self.pullFixture = pullFixture
    }
    
    func prepare() {}
    
    func pull(filter: TestFilter?) async throws -> [T] {
        try await Task.sleep(for: 0.5)
        return try await self.pullFixture(filter)
    }
    
    func push(_ items: [T]) async throws {
        print("Pushed items: \(items)")
        try await self.pushFixture(items)
    }
}
