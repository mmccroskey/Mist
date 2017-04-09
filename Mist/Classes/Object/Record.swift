//
//  Record.swift
//  RealmMist
//
//  Created by Matthew McCroskey on 2/3/17.
//  Copyright © 2017 Less But Better. All rights reserved.
//

import Foundation
import RealmSwift
import CloudKit


public typealias RecordID = String


open class Record : MistObject {
    
    
    // MARK: - PUBLIC -
    
    
    // MARK: - Properties
    
    open func propertyKeys() -> Set<String> {
        return Set([])
    }
    
    open func relationshipKeys() -> Set<String> {
        return Set([])
    }
    
    open func assetKeys() -> Set<String> {
        return Set([])
    }
    
    final func allKeys() -> Set<String> {
        return propertyKeys().union(relationshipKeys()).union(assetKeys())
    }
    
    
    // MARK: - INTERNAL
    
    
    // MARK: - Initializers
    
    internal func updateWithContentsOfRemoteRecord(_ backingRemoteRecord:CKRecord) {
        
        for key in backingRemoteRecord.allKeys() {
            
            if let objectForKey = backingRemoteRecord.object(forKey: key) {
                
                if let _ = objectForKey as? CKReference {
                    
                    // TODO: Handle References
                    fatalError("References not yet supported!")
                    
                } else if let _ = objectForKey as? CKAsset {
                    
                    // TODO: Do shit with Assets
                    fatalError("Assets not yet supported!")
                    
                } else {
                    
                    setValue(objectForKey, forKey: key)
                    
                }
                
            }
            
        }
        
    }
    
    
    // MARK: - Properties
    
    internal var database: Database? = nil
    
    
    // MARK: - Relationships
    
    internal dynamic var recordZone: RecordZone? = nil
    
    
    // MARK: - Functions
    
    /**
     Produce the CKRecord-equivalent of the Record
     
     :return: The CKRecord that is created from the Record on which the function is called.
     */
    internal func cloudKitRepresentation() -> (CKRecord, Set<CKRecord>, Set<CKReference>, Set<CKAsset>) {
        
        var relatedRecords: Set<CKRecord> = []
        var relatedReferences: Set<CKReference> = []
        var relatedAssets: Set<CKAsset> = []
        
        let coder = NSKeyedUnarchiver(forReadingWith: self.encodedSystemFields)
        
        guard let record = CKRecord(coder: coder) else {
            fatalError("Could not produce a CKRecord from the encodedSystemFields: \(self.encodedSystemFields)")
        }
        
        coder.finishDecoding()
        
        
        for propertyKey in propertyKeys() {
            
            if let propertyValue = value(forKey: propertyKey) {
                
                if let bool = propertyValue as? Bool {
                    
                    let number = NSNumber(booleanLiteral: bool)
                    record.setObject(number, forKey: propertyKey)
                    
                } else if let int = propertyValue as? Int {
                    
                    let number = NSNumber(integerLiteral: int)
                    record.setObject(number, forKey: propertyKey)
                    
                } else if let float = propertyValue as? Float {
                    
                    let number = NSNumber(floatLiteral: Double(float))
                    record.setObject(number, forKey: propertyKey)
                    
                } else if let double = propertyValue as? Double {
                    
                    let number = NSNumber(floatLiteral: double)
                    record.setObject(number, forKey: propertyKey)
                    
                } else if let string = propertyValue as? String {
                    
                    let cocoaString = NSString(string: string)
                    record.setObject(cocoaString, forKey: propertyKey)
                    
                } else if let cocoaString = propertyValue as? NSString {
                    
                    record.setObject(cocoaString, forKey: propertyKey)
                    
                } else if let date = propertyValue as? Date {
                    
                    let cocoaDate = NSDate(timeInterval: 0, since: date)
                    record.setObject(cocoaDate, forKey: propertyKey)
                    
                } else if let cocoaDate = propertyValue as? NSDate {
                    
                    record.setObject(cocoaDate, forKey: propertyKey)
                    
                } else {
                    
                    fatalError("All properties must be of one of the following types: Bool, Int, Float, Double, String, Date, or Data.")
                    
                }
                
            }
            
        }
        
        for relationshipKey in relationshipKeys() {
            
            if let relatedValue = value(forKey: relationshipKey) {
                
                guard let relatedRecord = relatedValue as? Record else {
                    
                    let relatedValueType = type(of: relatedValue)
                    
                    fatalError(
                        "Every value corresponding to a key in relationshipKeys must be an instance of Record, " +
                        "but the object for the key \(relationshipKey) within this Record was of type \(relatedValueType). " +
                        "Here's the Record in question: \(self)"
                    )
                    
                }
                
                let relatedRecordCloudKitRepresentation = relatedRecord.cloudKitRepresentation()
                
                let relatedCloudKitRecord = relatedRecordCloudKitRepresentation.0
                let reference = CKReference(record: relatedCloudKitRecord, action: .none)
                record.setObject(reference, forKey: relationshipKey)
                
                let relatedCloudKitRecordRelatedRecords = relatedRecordCloudKitRepresentation.1
                relatedRecords = relatedRecords.union(relatedCloudKitRecordRelatedRecords)
                
                let relatedCloudKitRecordRelatedReferences = relatedRecordCloudKitRepresentation.2
                relatedReferences = relatedReferences.union(relatedCloudKitRecordRelatedReferences)
                
                let relatedCloudKitRecordRelatedAssets = relatedRecordCloudKitRepresentation.3
                relatedAssets = relatedAssets.union(relatedCloudKitRecordRelatedAssets)
                
            }
            
        }
        
        for _ in assetKeys() {
            
            // TODO: Do shit with Assets
            fatalError("Assets not yet supported!")
            
        }
        
        return (record, relatedRecords, relatedReferences, relatedAssets)
        
    }
    
    
    // MARK: - PRIVATE
    
    
    // MARK: - Functions
    
    private func saveSystemFields(ofRemoteRecord remoteRecord: CKRecord) {
        
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        remoteRecord.encodeSystemFields(with: coder)
        coder.finishEncoding()
        self.encodedSystemFields = data as Data
        
    }
        
    
    
    // MARK: - Properties
    
    /**
     Encoding the system fields so that we can create a new CKRecord based on this
     */
    private dynamic var encodedSystemFields: Data!
    
    
    // MARK: - Realm Configuration Functions
    
    override open class func ignoredProperties() -> [String] {
        return ["databaseScope"]
    }
    
}


