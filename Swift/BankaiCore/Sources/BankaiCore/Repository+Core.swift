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

    /// Fetch elements of type filtering by [filter]
    ///
    public func fetch(
        filter: FilterType? = nil,
        on scheduler: AnySchedulerOf<DispatchQueue> = .global()
    ) -> RepoSnapshotFlow<[ValueType]> {
        let onlyLocally = filter?.onlyLocally ?? remotes.isEmpty
        let flow = RepoSnapshotFlow<[ValueType]>(onlyLocalExpected: onlyLocally)
        flow.scheduler = scheduler
        
        flow.run { receiver in
            var snapshot: [ValueType] = []
            
            do {
                snapshot = try await local.retrieve(filter: filter)
                print(">>> Got \(snapshot.count) results from local")
                receiver.send(local: snapshot)
            } catch {
                receiver.fail(with: .failedRetrieving(originalError: error))
            }
            
            for remote in remotes {
                do {
                    let remoteSnapshot = try await remote.pull(filter: filter)
                    resolveMostRecentData(fromLocal: &snapshot,
                                          andRemote: remoteSnapshot)
                    receiver.send(remote: snapshot)
                } catch {
                    receiver.fail(with: .failedPulling(originalError: error))
                }
            }
        }
        
        return flow
    }
    
    /// Given a local collection of N data, this function mixes and replaces
    /// as needed given an incoming remote collection of M data.
    /// - Parameters:
    ///     - snapshot: Reference to local snapshot of data.
    ///     This value will be mutated.
    ///     - remoteSnapshot: Collection of incoming remote values.
    /// - Side Effects:
    ///     - Any ID-matching items with a less recent update version
    ///       will be replaced.
    ///     - If no update mark is found to compare, remote will
    ///       take precedence.
    ///     - Any ID not found in the local source will be added.
    ///     - Any ID-matching item with a more recent local version will
    ///       remain the same.
    private func resolveMostRecentData(fromLocal snapshot: inout [ValueType],
                                       andRemote remoteSnapshot: [ValueType]) {
        for traceable in remoteSnapshot {
            let index = snapshot.firstIndex(where: { $0.id == traceable.id })
            
            guard let index else {
                snapshot.append(traceable)
                continue
            }
            
            guard let remoteDate = traceable.updatedAt,
                  let localDate = snapshot[index].updatedAt else {
                snapshot[index] = traceable
                continue
            }
            
            if remoteDate > localDate {
                snapshot[index] = traceable
            } else { continue }
        }
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
