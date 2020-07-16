//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/16.
//

import Foundation

public class AnyObserver {
    typealias RemoveHandler = () -> Bool
    typealias StoreInHandler = ((AnyObject?) -> ())
    
    private let remove: RemoveHandler
    private let storeIn: StoreInHandler
    
    init(removeHandler: @escaping RemoveHandler, storeInHandler: @escaping StoreInHandler) {
        remove = removeHandler
        storeIn = storeInHandler
    }
    
    public func store(in object: AnyObject?) {
        storeIn(object)
    }
    
    @discardableResult
    public func stop() -> Bool {
        return remove()
    }
}


