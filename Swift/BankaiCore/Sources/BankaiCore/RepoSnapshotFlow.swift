//
//  RepoSnapshotFlow.swift
//  
//
//  Created by Sergio Daniel on 1/09/24.
//

import Combine

enum RepoSyncError: Error {
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

public class RepoSnapshotFlow<Data> {
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
            case .remote(let data, let remoteName):
                self.yieldRemote(data, remoteName)
            }
        }
    }()
    
    var yieldLocal: (Data) -> Void = { _ in }
    var yieldRemote: (Data, String?) -> Void = { _, _ in }
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
    
    func send(remote data: Data, from remoteName: String? = nil) {
        guard !hasCompleted else { return }
        subject.send(.remote(data, remoteName))
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
    func flow() -> AnyCancellable {
        return self.cancellable
    }
}
