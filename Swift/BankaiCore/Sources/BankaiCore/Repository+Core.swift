//
//  Repository+Core.swift
//
//
//  Created by Sergio Daniel on 1/09/24.
//

extension Repository where ValueType == Local.ValueType, ValueType == Remote.ValueType, FilterType == Local.FilterType, FilterType == Remote.FilterType {
    
    public func fetch(filter: FilterType? = nil) -> RepoSnapshotFlow<[ValueType]> {
        let onlyLocally = filter?.onlyLocally ?? false
        let flow = RepoSnapshotFlow<[ValueType]>(onlyLocalExpected: onlyLocally)
        
        Task {
            var localSnapshot: [ValueType]?
            
            do {
                let snapshot = try await local.retrieve(filter: filter)
                flow.send(local: snapshot)
            } catch {
                flow.fail(with: .failedRetrieving(originalError: error))
            }
            
            if onlyLocally {
                return
            }
            
            for remote in remotes {
                do {
                    let snapshot = try await remote.pull(filter: filter)
                    flow.send(remote: snapshot)
                } catch {
                    
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
