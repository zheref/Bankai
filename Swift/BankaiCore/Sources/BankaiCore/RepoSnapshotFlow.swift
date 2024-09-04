//
//  RepoSnapshotFlow.swift
//  
//
//  Created by Sergio Daniel on 1/09/24.
//

import Combine
import Foundation

public enum RepoSyncError: Error {
    case failedStoring(originalError: Error)
    case failedPushing(originalError: Error)
    
    case failedRetrieving(originalError: Error)
    case failedPulling(originalError: Error)
}

enum RepoSnapshot<T> {
    // Happy paths
    case local(T)
    case remote(T, String?)
}

public protocol SnapshotReceiver {
    associatedtype Data
    
    func send(local data: Data)
    func send(remote data: Data, from remoteName: String?)
    func giveUp()
    func fail(with error: RepoSyncError)
}

/// Represents a flow of snapshots of the given data type. Intended
/// to retrieve data from a local source expecting a potential remote
/// snapshot to contrast data and decide which one to keep.
/// - Parameters:
///     - Data: The type of data to manage
public class RepositoryFlow<Data>: SnapshotReceiver {
    // MARK: - Subtypes
    typealias Receiver = RepositoryFlow
    
    let onlyLocalExpected: Bool
    var scheduler: AnySchedulerOf<DispatchQueue> = .global()
    
    // Whether the flow has completed already or not.
    var hasCompleted: Bool = false
    
    private var body: (Receiver) async throws -> Void = { _ in }
    
    /// Subject holding flow of snapshots over time until it completes.
    private let subject = SubjectOf<RepoSnapshot<Data>, RepoSyncError>()
    
    func run() -> AnyCancellable {
        subject
            .receive(on: scheduler)
            .print("zheref")
            .subscribe(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { _ in
                Task { try await self.body(self) }
            }, receiveOutput: { snapshot in
                print(">>> Received snapshot")
                switch snapshot {
                case .local(let data):
                    print(">>> Flow detected incoming local data")
                    self.yieldLocal(data)
                case .remote(let data, let remoteName):
                    self.yieldRemote(data, remoteName)
                }
            }, receiveCompletion: { completion in
                print(">>> Received completion")
                self.hasCompleted = true
                switch completion {
                case .finished:
                    self.yieldCompletion()
                case .failure(let error):
                    self.yieldFailure(error)
                }
            })
            .sink { _ in } receiveValue: { _ in }
    }
    
    var yieldLocal: (Data) -> Void = { _ in }
    var yieldRemote: (Data, String?) -> Void = { _, _ in }
    var yieldFailure: (RepoSyncError) -> Void = { _ in }
    var yieldCompletion: () -> Void = { }
    
    init(onlyLocalExpected: Bool = false) {
        self.onlyLocalExpected = onlyLocalExpected
    }
    
    // Send values
    
    func run(_ op: @escaping (Receiver) async throws -> Void) 
        where Receiver: SnapshotReceiver, Receiver.Data == Data {
        self.body = op
    }
    
    public func send(local data: Data) {
        guard !hasCompleted else { return }
        print(">>> Will deliver local data")
        subject.send(.local(data))
        if onlyLocalExpected {
            subject.send(completion: .finished)
        }
    }
    
    public func send(remote data: Data, from remoteName: String? = nil) {
        guard !hasCompleted else { return }
        subject.send(.remote(data, remoteName))
        subject.send(completion: .finished)
    }
    
    public func giveUp() {
        guard !hasCompleted else { return }
        subject.send(completion: .finished)
    }
    
    public func fail(with error: RepoSyncError) {
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
    func onRemote(_ yield: @escaping (Data, String?) -> Void) -> Self {
        self.yieldRemote = yield
        return self
    }
    
    @discardableResult
    func onFailure(_ yield: @escaping (RepoSyncError) -> Void) -> Self {
        self.yieldFailure = yield
        return self
    }
    
    @discardableResult
    func onCompletion(_ yield: @escaping () -> Void) -> Self {
        self.yieldCompletion = yield
        return self
    }
}
