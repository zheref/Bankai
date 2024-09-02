//
//  Repository+Core.swift
//
//
//  Created by Sergio Daniel on 1/09/24.
//

import Combine
import Foundation

extension Repository 
    where ValueType == Local.ValueType, ValueType == Remote.ValueType,
            FilterType == Local.FilterType, FilterType == Remote.FilterType
{

    ///
    ///
    public func fetch(filter: FilterType? = nil, on scheduler: AnySchedulerOf<DispatchQueue> = .global()) -> RepoSnapshotFlow<[ValueType]> {
        let onlyLocally = filter?.onlyLocally ?? remotes.isEmpty
        let flow = RepoSnapshotFlow<[ValueType]>(onlyLocalExpected: onlyLocally)
        flow.scheduler = scheduler
        
        flow.run { receiver in
            var localSnapshot: [ValueType]?
            
            do {
                let snapshot = try await local.retrieve(filter: filter)
                print(">>> Got \(snapshot.count) results from local")
                receiver.send(local: snapshot)
            } catch {
                receiver.fail(with: .failedRetrieving(originalError: error))
            }
            
            for remote in remotes {
                do {
                    let snapshot = try await remote.pull(filter: filter)
                    receiver.send(remote: snapshot)
                } catch {
                    receiver.fail(with: .failedPulling(originalError: error))
                }
            }
        }
        
        return flow
    }
    
    public func save(_ items: [ValueType], andAttemptToPush shouldAttemptToPush: Bool = true) async throws {
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
