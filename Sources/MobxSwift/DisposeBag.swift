//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/16.
//

import Foundation

public final class DisposeBag {
    private var observers = [AnyObserver]()
    
    func addObserver(_ observer: AnyObserver) {
        observers.append(observer)
    }
    
    public func stop() {
        observers.forEach { $0.stop() }
    }
}

extension AnyObserver {
    public func store(in bag: DisposeBag) {
        bag.addObserver(self)
        store(in: bag as AnyObject?)
    }
}
