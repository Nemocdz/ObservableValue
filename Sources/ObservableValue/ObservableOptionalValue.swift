//
//  File.swift
//  
//
//  Created by Nemo on 2020/7/23.
//

import Foundation

public protocol ObservableOptionalValue {
    associatedtype Wrapped
    var wrapped: Wrapped { get }
    var isNil: Bool { get }
}

extension Optional: ObservableOptionalValue {
    public var wrapped: Wrapped { unsafelyUnwrapped }
    public var isNil: Bool { self == nil }
}
