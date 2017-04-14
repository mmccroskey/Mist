//
//  ScopedDataStore.swift
//  Pods
//
//  Created by Matthew McCroskey on 3/30/17.
//
//

import Foundation
import RealmSwift

internal class ScopedDataStore : MistObject {
    
    
    // MARK: - Initializer
    
    convenience init(databaseScope: DatabaseScope, userId: String?=nil) {
        
        self.init()
        
        self.databaseScope = databaseScope
        self.userId = userId
        
    }
    
    
    // MARK: - Properties
    
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
    
    dynamic var userId: String?
    
    
    // MARK: - Relationships
    
    dynamic var defaultRecordZone: RecordZone?
    
    let recordZones = LinkingObjects(fromType: RecordZone.self, property: "scopedDataStore")
    
    func records(pulledFromRealm realm:Realm) -> Results<Record> {
        return realm.objects(Record.self).filter("recordZone IN %@", recordZones)
    }
    
    
    // MARK: - Shamed Raw Persistence Values
    
    private dynamic var databaseScopeRawValue: Int = -1
    
    
    // MARK: - Realm Configuration Functions
    
    override open class func ignoredProperties() -> [String] {
        return ["databaseScope"]
    }
    
}
