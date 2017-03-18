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

internal class RecordZone : Object {
    
    
    // MARK: - Initializers
    
    convenience init(database: Database) {
        
        self.init()
        
        self.database = database
        
    }
    
    convenience init(zoneName: String, database: Database) {
        
        self.init()
        
        self.zoneName = zoneName
        self.database = database
    
    }
    
    
    // MARK: - Properties
    
    private(set) var backingRecordZoneID: CKRecordZoneID {
        
        get {
            return CKRecordZoneID(zoneName: zoneName, ownerName: ownerName)
        }
        
        set {
            
            self.zoneName = newValue.zoneName
            self.ownerName = newValue.ownerName
            
        }
    }
    
    private(set) var database: Database! {
        
        didSet {
            updateCombinedIdentifier()
        }
        
    }
    
    
    // MARK: - Relationships
    
    let records = LinkingObjects(fromType: Record.self, property: "recordZone")
    
    
    // MARK: - Private Properties
    
    dynamic var zoneName: String = "default" {
        
        didSet {
            updateCombinedIdentifier()
        }
        
    }
    
    dynamic var ownerName: String = CKCurrentUserDefaultName {
        
        didSet {
            updateCombinedIdentifier()
        }
        
    }
    
    dynamic var combinedIdentifier: String = UUID().uuidString
    
    
    // MARK: - Private Functions
    
    private func updateCombinedIdentifier() {
        combinedIdentifier = "\(database.scopeName)+\(zoneName)+\(ownerName)"
    }
    
    
    // MARK: - Realm Configuration Functions
    
    override static func primaryKey() -> String? {
        return "combinedIdentifier"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["backingRecordZoneID","database"]
    }
    
}
