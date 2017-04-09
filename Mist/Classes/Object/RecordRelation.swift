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
    
}
