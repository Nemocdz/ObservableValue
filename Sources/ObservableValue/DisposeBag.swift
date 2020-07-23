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
    
    /// 移除所有已加入的观察
    public func disposeAll() {
        bag.forEach { $0.dispose() }
    }
    
    deinit {
        disposeAll()
    }
}
