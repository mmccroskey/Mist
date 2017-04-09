//
//  RecordZone.swift
//  RealmMist
//
//  Created by Matthew McCroskey on 2/4/17.
//  Copyright © 2017 Less But Better. All rights reserved.
//

import Foundation
import RealmSwift
import CloudKit

internal typealias RecordZoneID = String

internal class RecordZone : MistObject {
    
    
    // MARK: - Initializers
    
    // Used by Database, etc.
    convenience init(scopedDataStore:ScopedDataStore) {
        
        self.init()
        
        self.scopedDataStore = scopedDataStore
        
    }
    
    // Used by CloudKit to create local copies of DBs already in the cloud
    convenience init(scopedDataStore:ScopedDataStore, zoneName: String) {
        
        self.init()
        
        self.scopedDataStore = scopedDataStore
        self.zoneName = zoneName
        
    }
    
    
    // MARK: - Properties
    
    var backingRecordZone: CKRecordZone {
        return CKRecordZone(zoneName: zoneName)
    }
    
    private(set) var zoneName: String {
        get { return id }
        set { id = newValue }
    }
    
    
    // MARK: - Relationships
    
    dynamic var scopedDataStore: ScopedDataStore?
    
    let recordRelations = LinkingObjects(fromType: RecordRelation.self, property: "recordZone")
    
    
    
    // MARK: - Realm Configuration Functions
    
    override static func ignoredProperties() -> [String] {
        return ["backingRecordZone","zoneName"]
    }
    
}
