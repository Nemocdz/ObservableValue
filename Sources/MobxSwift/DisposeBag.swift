//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/16.
//

import Foundation

public final class DisposeBag {
    private var bag = [Disposable]()
    
    func add(_ disposable: Disposable) {
        bag.append(disposable)
    }
    
    public func stop() {
        bag.forEach { $0.dispose() }
    }
}

extension Disposable {
    public func add(to bag: DisposeBag) {
        bag.add(self)
        add(to: bag as AnyObject?)
    }
}
