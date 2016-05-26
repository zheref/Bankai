//
//  BKMemcache.swift
//  Bankai
//
//  Created by Sergio Daniel Lozano on 5/26/16.
//  Copyright © 2016 Sergio Daniel L Garcia. All rights reserved.
//

import Foundation

public protocol BKMemcacheObserver
{
    func memcacheHasChanged(forKey key: String) -> Void
}

public class BKMemcache {
    
    private typealias MemcacheCollection = [String: ([AnyObject], BKMemcacheObserver?)]
    
    // MARK: SINGLETON
    
    /**
     * Unique Memcache singleton reference (lazy-loaded)
     */
    private static var _instance: BKMemcache = {
        return BKMemcache()
    }()
    
    /**
     * Unique Memcache singleton accesor
     */
    internal static var shared: BKMemcache {
        get { return BKMemcache._instance }
    }
    
    // PROPERTIES ---------------------------------------------------------------------------------
    
    private var _data: MemcacheCollection
    
    // INITIALIZERS -------------------------------------------------------------------------------
    
    init() {
        _data = MemcacheCollection()
    }
    
    // SUBSCRIPT ----------------------------------------------------------------------------------
    
    internal subscript(cacheKey: String) -> [AnyObject]? {
        get {
            if let obj = _data[cacheKey] {
                return obj.0
            } else {
                return nil
            }
        }
    }
    
    // METHODS ------------------------------------------------------------------------------------
    
    /**
     * Caches a given object with the given key. If it's already there, it updates
     * - Parameter cacheKey String: Key with what the data will be cached
     * - Parameter dataItem [AnyObject]:
     */
    internal func addOrUpdateKey(cacheKey: String, withData dataItem: [AnyObject],
                                 beingWatchedBy dataObserver: BKMemcacheObserver? = nil)
    {
        if _data[cacheKey] == nil {
            _data[cacheKey] = (dataItem, dataObserver)
        } else {
            if dataObserver != nil {
                _data.updateValue((dataItem, dataObserver), forKey: cacheKey)
                dataObserver!.memcacheHasChanged(forKey: cacheKey)
            } else {
                let observer = _data[cacheKey]!.1
                _data.updateValue((dataItem, observer), forKey: cacheKey)
                
                if observer != nil {
                    observer!.memcacheHasChanged(forKey: cacheKey)
                }
            }
        }
    }
    
    /**
     * Determines whether a key has been already cached or not
     */
    internal func hasKey(cacheKey: String) -> Bool {
        return _data[cacheKey] != nil
    }
    
}