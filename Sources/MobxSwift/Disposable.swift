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

    @discardableResult
    public func add(to object: AnyObject?) -> Disposable {
        add(object)
        return self
    }
    
    @discardableResult
    public func unowned() -> Disposable {
        add(to: self)
    }
    
    @discardableResult
    public func dispose() -> Bool {
        return remove()
    }
}


