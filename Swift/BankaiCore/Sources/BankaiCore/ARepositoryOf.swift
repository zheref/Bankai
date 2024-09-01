//
//  ARepositoryOf.swift
//
//
//  Created by Sergio Daniel on 1/09/24.
//

// Complements with: RepositoryCore
public struct ARepositoryOf<V, F, L, R>: Repository
    where V: Traceable, F: Filter, L: LocalDataSource, R: RemoteDataSource,
        L.FilterType == F, L.ValueType == V, R.FilterType == F, R.ValueType == V
{
    public typealias FilterType = F
    public typealias ValueType = V
    public typealias Local = L
    public typealias Remote = R
    
    public var local: L
    public var remotes: [R]
    
    public init(local: L) {
        self.local = local
        self.remotes = []
    }
    
    public mutating func prepare() {
        local.prepare()
        
        for i in 0..<remotes.count {
            remotes[i].prepare()
        }
    }
    
    public mutating func add(remote: R) {
        remotes.append(remote)
    }
}
