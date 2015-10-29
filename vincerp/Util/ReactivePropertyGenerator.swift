//
// Created by Viktor Belenyesi on 25/09/15.
// Copyright (c) 2015 Viktor Belenyesi. All rights reserved.
//

class ReactivePropertyGeneator {
    
    // TODO: unittest -> check for memory leaks
    private static var propertyMap = [String:Reactor]()
    private static var observerMap = [String:PropertyObserver]()
    
    init() {}
    
    static func getKey(targetObject: AnyObject, propertyName: String) -> String {
        return  "\(targetObject.hash)\(propertyName) "
    }
    
    static func getEmitter<T:Equatable>(targetObject: AnyObject, propertyName: String) -> Source<T>? {
        let key = getKey(targetObject, propertyName: propertyName)
        return propertyMap[key] as! Source<T>?
    }
    
    static func synthesizeEmitter<T:Equatable>(initValue: T) -> Source<T> {
        return Source<T>(initValue: initValue)
    }
    
    static func synthesizeObserver<T:Equatable>(targetObject: AnyObject, propertyName: String, initValue: T) -> PropertyObserver {
        return PropertyObserver(targetObject: targetObject as! NSObject, propertyName: propertyName) { (currentTargetObject: NSObject, currentPropertyName:String, currentValue:AnyObject)  in
            if let existingEmitter:Source<T> = getEmitter(currentTargetObject, propertyName: propertyName) {
                existingEmitter.update(currentValue as! T)
            }
        }
    }
    
    static func createEmitter<T:Equatable>(targetObject: AnyObject, propertyName: String, initValue: T) -> Source<T> {
        let result = synthesizeEmitter(initValue)
        let key = getKey(targetObject, propertyName: propertyName)
        propertyMap[key] = result
        return result
    }
    
    static func createObserver<T:Equatable>(targetObject: AnyObject, propertyName: String, initValue: T) -> PropertyObserver {
        let result = synthesizeObserver(targetObject, propertyName: propertyName, initValue: initValue)
        let key = getKey(targetObject, propertyName: propertyName)
        observerMap[key] = result
        return result
    }
    
    static func emitter<T:Equatable>(targetObject: AnyObject, propertyName: String, initValue: T, initializer: ((Source<T>) -> ())? = nil) -> Source<T> {
        if let emitter:Source<T> = getEmitter(targetObject, propertyName: propertyName) {
            return emitter
        }
        
        let emitter = createEmitter(targetObject, propertyName: propertyName, initValue: initValue)
        if let i = initializer {
            i(emitter)
        }
        return emitter
    }
    
    static func property<T:Equatable>(targetObject: AnyObject, propertyName: String, initValue: T, initializer: ((Source<T>) -> ())? = nil) -> Rx<T> {
        let result = emitter(targetObject, propertyName: propertyName, initValue: initValue, initializer: initializer)
        createObserver(targetObject, propertyName: propertyName, initValue: initValue)
        return result as Rx<T>
    }
}

private var propertyObserverContext = 0

class PropertyObserver: NSObject {
    let targetObject: NSObject
    let propertyName: String
    let propertyChangeHandler: (NSObject, String, AnyObject) -> Void
    
    init(targetObject:NSObject, propertyName: String, propertyChangeHandler: (NSObject, String, AnyObject) -> Void) {
        self.targetObject = targetObject
        self.propertyName = propertyName
        self.propertyChangeHandler = propertyChangeHandler
        super.init()
        self.targetObject.addObserver(self, forKeyPath: propertyName, options: .New, context: &propertyObserverContext)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &propertyObserverContext {
            if self.propertyName == keyPath {
                if let newValue = change?[NSKeyValueChangeNewKey] {
                    self.propertyChangeHandler(self.targetObject, self.propertyName, newValue)
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    deinit {
        self.targetObject.removeObserver(self, forKeyPath: propertyName, context: &propertyObserverContext)
    }
}

public extension UIResponder {
    
    public func reactiveProperty<T:Equatable>(forProperty propertyName: String, initValue: T, initializer: ((Source<T>) -> ())? = nil) -> Rx<T> {
        return ReactivePropertyGeneator.property(self, propertyName: propertyName, initValue: initValue, initializer: initializer)
    }
    
    public func reactiveEmitter<T:Equatable>(name propertyName: String, initValue: T) -> Source<T> {
        return ReactivePropertyGeneator.emitter(self, propertyName: propertyName, initValue: initValue)
    }
    
}
