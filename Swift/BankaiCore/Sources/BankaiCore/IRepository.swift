//
//  IRepository.swift
//  
//
//  Created by Sergio Daniel on 13/08/24.
//

import Combine
import Foundation

protocol ILocal {
    associatedtype T: Traceable
    
    func store(_ items: [T]) async throws
    func retrieve() async throws -> [T]
}

protocol IRemote {
    associatedtype T: Traceable
    
    static var name: String { get }
    
    func pull() async throws -> [T]
    func push(_ items: [T]) async throws
}

protocol IRepository {
    associatedtype T: Traceable
    associatedtype Local: ILocal
    associatedtype Remote: IRemote
    
    var local: Local { get }
    var remotes: [Remote] { get set }
    
    init(local: Local)
    
    func fetch(onlyLocally: Bool) -> RepoSnapshotFlow<[T]>
    func save(_ items: [T], andAttemptToPush shouldAttemptToPush: Bool) async throws
    
    mutating func add(remote: Remote)
}

enum RepoSyncError: Error {
    case failedStoring(originalError: Error)
    case failedPushing(originalError: Error)
    
    case failedRetrieving(originalError: Error)
    case failedPulling(originalError: Error)
}

enum RepoSnapshot<T> {
    // Happy paths
    case local(T)
    case remote(T)
}

class RepoSnapshotFlow<Data> {
    let onlyLocalExpected: Bool
    
    private let subject = ZSubjectOf<RepoSnapshot<Data>, RepoSyncError>()
    var hasCompleted: Bool = false
    
    lazy var cancellable: AnyCancellable = {
        return subject.sink { completion in
            self.hasCompleted = true
            switch completion {
            case .finished:
                self.complete()
            case .failure(let error):
                self.yieldFailure(error)
            }
        } receiveValue: { snapshot in
            switch snapshot {
            case .local(let data):
                self.yieldLocal(data)
            case .remote(let data):
                self.yieldRemote(data)
            }
        }
    }()
    
    var yieldLocal: (Data) -> Void = { _ in }
    var yieldRemote: (Data) -> Void = { _ in }
    var yieldFailure: (RepoSyncError) -> Void = { _ in }
    var complete: () -> Void = { }
    
    init(onlyLocalExpected: Bool = false) {
        self.onlyLocalExpected = onlyLocalExpected
    }
    
    // Send values
    
    func send(local data: Data) {
        guard !hasCompleted else { return }
        subject.send(.local(data))
        if onlyLocalExpected {
            subject.send(completion: .finished)
        }
    }
    
    func send(remote data: Data) {
        guard !hasCompleted else { return }
        subject.send(.remote(data))
        subject.send(completion: .finished)
    }
    
    func giveUp() {
        guard !hasCompleted else { return }
        subject.send(completion: .finished)
    }
    
    func fail(with error: RepoSyncError) {
        guard !hasCompleted else { return }
        subject.send(completion: .failure(error))
    }
    
    // Subscribe to events
    
    @discardableResult
    func onLocal(_ yield: @escaping (Data) -> Void) -> Self {
        self.yieldLocal = yield
        return self
    }
    
    @discardableResult
    func onRemote(_ yield: @escaping (Data) -> Void) -> Self {
        self.yieldRemote = yield
        return self
    }
    
    @discardableResult
    func onFailure(_ yield: @escaping (RepoSyncError) -> Void) -> Self {
        self.yieldFailure = yield
        return self
    }
    
    @discardableResult
    func flow() -> AnyCancellable {
        return self.cancellable
    }
}

protocol Traceable: Identifiable {
    var modifiedAt: Date { get }
}

extension IRepository where T == Local.T, T == Remote.T {
    
    func fetch(onlyLocally: Bool = false) -> RepoSnapshotFlow<[T]> {
        let flow = RepoSnapshotFlow<[T]>(onlyLocalExpected: onlyLocally)
        
        Task {
            var localSnapshot: [T]?
            
            do {
                let snapshot = try await local.retrieve()
                flow.send(local: snapshot)
            } catch {
                flow.fail(with: .failedRetrieving(originalError: error))
            }
            
            if onlyLocally {
                return
            }
            
            for remote in remotes {
                do {
                    let snapshot = try await remote.pull()
//                    flow.send(remote: <#T##[Traceable]#>)
                } catch {
                    
                }
            }
        }
        
        return flow
    }
    
    func save(_ items: [T], andAttemptToPush shouldAttemptToPush: Bool = true) async throws {
        do {
            try await local.store(items)
        } catch {
            throw RepoSyncError.failedStoring(originalError: error)
        }
        
        do {
            for remote in remotes {
                try await remote.push(items)
            }
        } catch {
            throw RepoSyncError.failedPushing(originalError: error)
        }
    }
    
    mutating func add(remote: Remote) {
        remotes.append(remote)
    }
    
}
