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
    typealias Operation = (Receiver) async throws -> Void
    
    // MARK: - Instance Members
    
    let onlyLocalExpected: Bool
    
    
    // Whether the flow has completed already or not.
    var hasCompleted: Bool = false
    
    /// The operation block to be run when the flow is started.
    /// The body of the operation to be performed by the flow which should
    /// deliver values across time in order to flow to successfully complete.
    private var body: (Receiver) async throws -> Void = { _ in }
    
    private let scheduler: AnySchedulerOf<DispatchQueue>
    
    /// Subject holding flow of snapshots over time until it completes.
    private let subject = SubjectOf<RepoSnapshot<Data>, RepoSyncError>()
    
    private var _cancellable: AnyCancellable!
    
    /// Retrieves cancellable instance of the flow and registers handlers
    /// for each snapshot type.
    /// It also keeps an instance of cancellable in order to control flow
    /// from inside.
    func run() -> AnyCancellable {
        _cancellable = subject
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
        return _cancellable
    }
    
    var yieldLocal: (Data) -> Void = { _ in }
    var yieldRemote: (Data, String?) -> Void = { _, _ in }
    var yieldFailure: (RepoSyncError) -> Void = { _ in }
    var yieldCompletion: () -> Void = { }
    
    // MARK: Constructors
    
    /// Creates a new instance of RepositoryFlow.
    /// Registers the operation to be run when the flow is started.
    /// This operation block will be responsible for emitting new snapshots
    /// or events to the flow.
    /// - Parameters:
    ///     - onlyLocalExpected: Whether the flow will only expect a 
    ///     local snapshot or also expect remote snapshots.
    ///     - scheduler: The scheduler where the flow should operate.
    ///     - operation: Async operation block taking a receiver handler
    ///     to send new snapshots/events with.
    init(onlyLocalExpected: Bool = false,
         scheduler: AnySchedulerOf<DispatchQueue> = .global(),
         _ operation: @escaping Operation) {
        self.onlyLocalExpected = onlyLocalExpected
        self.scheduler = scheduler
        self.body = operation
    }
    
    // MARK: - Sending values
    
    /// Sends a local snapshot to the flow so that subscribers are notified.
    /// - Parameters:
    ///     - local: The snapshot of data to send to the flow as local.
    public func send(local data: Data) {
        guard !hasCompleted else { return }
        print(">>> Will deliver local data")
        subject.send(.local(data))
        if onlyLocalExpected {
            subject.send(completion: .finished)
        }
    }
    
    /// Sends a remote snapshot to the flow so that subscribers are notified.
    /// - Parameters:
    ///     - remote: The value to be received by the flow.
    ///     - from: The name of the remote sending the new value.
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
