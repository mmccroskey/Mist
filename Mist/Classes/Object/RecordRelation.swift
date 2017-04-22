//
//  RecordRelation.swift
//  Pods
//
//  Created by Matthew McCroskey on 4/9/17.
//
//

import Foundation
import RealmSwift

internal class RecordRelation : MistObject {
    
    
    // MARK: - Initializer
    
    convenience init(relatedRecordClassName:String, relatedRecordId:String, recordZone: RecordZone) {
        
        self.init()
        
        self.relatedRecordClassName = relatedRecordClassName
        self.relatedRecordId = relatedRecordId
        
        self.recordZone = recordZone
        
    }
    
    
    // MARK: - Properties
    
    dynamic var relatedRecordClassName: String = ""
    dynamic var relatedRecordId: String = ""
    
    
    // MARK: - Relationships
    
    dynamic var recordZone: RecordZone?
    
    
    // MARK: - Mist Configuration Functions
    
    override func beforeDelete(_ realm: Realm) {
        
        if let relatedObject = realm.dynamicObject(ofType: relatedRecordClassName, forPrimaryKey: relatedRecordId) as Object? {
            
            guard let relatedRecord = relatedObject as? Record else {
                fatalError("Could not convert RecordRelation's respective relation object to a Record")
            }
            
            realm.mistDelete(relatedRecord)
            
        }
        
    }
    
}
