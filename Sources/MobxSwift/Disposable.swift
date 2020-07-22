//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/16.
//

import Foundation

public class Disposable {
    typealias AddHandler = ((AnyObject?) -> ())
    typealias RemoveHandler = () -> Bool
    
    private let add: AddHandler
    private let remove: RemoveHandler
    
    init(addHandler: @escaping AddHandler, removeHandler: @escaping RemoveHandler) {
        add = addHandler
        remove = removeHandler
    }
    
    public func add(to object: AnyObject?) {
        add(object)
    }
    
    @discardableResult
    public func dispose() -> Bool {
        return remove()
    }
}


