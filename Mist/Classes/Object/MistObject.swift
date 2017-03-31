//
//  MistObject.swift
//  Pods
//
//  Created by Matthew McCroskey on 3/30/17.
//
//

import Foundation
import RealmSwift

open class MistObject : Object {
    
    
    // MARK: - Properties
    
    open internal(set) dynamic var id: String = UUID().uuidString
    
    
    // MARK: - Realm Configuration Functions
    
    override open static func primaryKey() -> String? {
        return "id"
    }
    
}
