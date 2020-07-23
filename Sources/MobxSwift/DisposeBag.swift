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
    
    /// 移除所有关联的监听
    public func disposeAll() {
        bag.forEach { $0.dispose() }
    }
}

extension Disposable {
    
    /// 跟随 bag 生命周期移除监听
    /// - Parameter bag: bag
    @discardableResult public func add(to bag: DisposeBag) -> Disposable {
        bag.add(self)
        return add(to: bag as AnyObject?)
    }
}
