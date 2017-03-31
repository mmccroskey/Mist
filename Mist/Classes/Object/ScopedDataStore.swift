//
//  ScopedDataStore.swift
//  Pods
//
//  Created by Matthew McCroskey on 3/30/17.
//
//

import Foundation
import RealmSwift

internal class ScopedDataStore : Object {
    
    
    // MARK: - Initializer
    
    convenience init(databaseScope: DatabaseScope, user: User?=nil) {
        
        self.init()
        
        self.databaseScope = databaseScope
        self.user = user
        
    }
    
    
    // MARK: - Properties
    
    private(set) dynamic var id: String = UUID().uuidString
    
    var databaseScope: DatabaseScope {
        
        get {
            
            guard let scope = DatabaseScope(rawValue: databaseScopeRawValue) else {
                fatalError("databaseScopeRawValue must always contain an int in the range [0-2].")
            }
            
            return scope
            
        }
        
        set {
            
            databaseScopeRawValue = newValue.rawValue
            
        }
        
    }
    
    dynamic var user: User?
    
    
    // MARK: - Relationships
    
    func records(pulledFromRealm realm:Realm) -> Results<Record> {
        return realm.objects(Record.self).filter("recordZone IN %@", recordZones)
    }
    
    let recordZones = LinkingObjects(fromType: RecordZone.self, property: "scopedDataStore")
    
    
    // MARK: - Shamed Raw Persistence Values
    
    private dynamic var databaseScopeRawValue: Int = -1
    
    
    // MARK: - Realm Configuration Functions
    
    override open class func primaryKey() -> String? {
        return "id"
    }
    
    override open class func ignoredProperties() -> [String] {
        return ["databaseScope"]
    }
    
}
