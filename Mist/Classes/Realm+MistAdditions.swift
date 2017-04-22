//
//  Realm+MistAdditions.swift
//  Pods
//
//  Created by Matthew McCroskey on 4/21/17.
//
//

import Foundation
import RealmSwift

internal extension Realm {
    
    
    // MARK: - Customized Add Functions
    
    internal func mistAdd(_ object: MistObject, update: Bool = false) {
        
        add(object, update: update)
        object.afterAdd(self)
        
    }
    
    internal func mistAdd<S: Sequence>(_ objects: S, update: Bool = false) where S.Iterator.Element: MistObject {
        
        add(objects, update: update)
        
        for object in objects {
            object.afterAdd(self)
        }
        
    }
    
    
    // MARK: - Customized Delete Functions
    
    internal func mistDelete(_ object: MistObject) {
        
        object.beforeDelete(self)
        delete(object)
        
    }
    
    internal func mistDelete<S: Sequence>(_ objects: S) where S.Iterator.Element: MistObject {
        
        for object in objects {
            object.beforeDelete(self)
        }
        
        delete(objects)
        
    }
    
    internal func mistDelete<T: MistObject>(_ objects: List<T>) {
        
        for object in objects {
            object.beforeDelete(self)
        }
        
        delete(objects)
        
    }
    
    internal func delete<T: MistObject>(_ objects: Results<T>) {
        
        for object in objects {
            object.beforeDelete(self)
        }
        
        delete(objects)
        
    }
    
}
