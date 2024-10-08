//
//  IRepository.swift
//  
//
//  Created by Sergio Daniel on 13/08/24.
//

import Combine
import Foundation

public protocol Filter {
    var onlyLocally: Bool { get set }
}

public protocol Traceable: Identifiable {
    var updatedAt: Date? { get }
}

public protocol DataSource {
    mutating func prepare()
}

public protocol LocalDataSource: DataSource {
    associatedtype FilterType: Filter
    associatedtype ValueType: Traceable
    
    func store(_ items: [ValueType]) async throws
    func retrieve(filter: FilterType?) async throws -> [ValueType]
}

public protocol RemoteDataSource: DataSource {
    associatedtype FilterType: Filter
    associatedtype ValueType: Traceable
    
    static var name: String { get }
    var label: String { get }
    
    func pull(filter: FilterType?) async throws -> [ValueType]
    func push(_ items: [ValueType]) async throws
}

extension RemoteDataSource {
    var label: String { Self.name }
}

public protocol Repository: DataSource {
    associatedtype FilterType: Filter
    associatedtype ValueType: Traceable
    associatedtype Local: LocalDataSource
    associatedtype Remote: RemoteDataSource
    
    var local: Local { get }
    var remotes: [Remote] { get set }
    
    init(local: Local)
    
    func fetch(filter: FilterType?, on scheduler: AnySchedulerOf<DispatchQueue>) -> RepositoryFlow<[ValueType]>
    func save(_ items: [ValueType], andAttemptToPush shouldAttemptToPush: Bool) async throws
    
    // This should provide implementation at protocol/interface level
    mutating func add(remote: Remote)
}
