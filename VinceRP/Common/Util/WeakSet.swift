//
// Created by Viktor Belenyesi on 18/04/15.
// Copyright (c) 2015 Viktor Belenyesi. All rights reserved.
//
// https://github.com/scala/scala/blob/2.11.x/src/library/scala/ref/WeakReference.scala

class WeakReference<T: AnyObject where T: Hashable>: Hashable {
    weak var value: T?
    
    init(_ value: T) {
        self.value = value
    }
    
    var hashValue: Int {
        guard let v = self.value else {
            return 0
        }
        return v.hashValue
    }
}

func ==<T>(lhs: WeakReference<T>, rhs: WeakReference<T>) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

public class WeakSet<T: Hashable where T: AnyObject> {
    private var _array: [WeakReference<T>]
    
    public init() {
        _array = Array()
    }

    public init(_ array: [T]) {
        _array = array.map {
            WeakReference($0)
        }
    }
    
    public var set: Set<T> {
        return Set(self.array())
    }

    public func insert(member: T) {
        for e in _array {
            if e.hashValue == member.hashValue {
                return
            }
        }
        _array.append(WeakReference(member))
    }

    public func filter(@noescape includeElement: (T) -> Bool) -> WeakSet<T> {
        return WeakSet(self.array().filter(includeElement))
    }

    public func hasElementPassingTest(@noescape filterFunc: (T) -> Bool) -> Bool {
        return self.array().hasElementPassingTest(filterFunc)
    }
    
    private func array() -> Array<T> {
        var result = Array<T>()
        for item in _array {
            if let v = item.value {
                result.append(v)
            }
        }
        return result
    }

}
