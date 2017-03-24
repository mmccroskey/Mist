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
public typealias RecordValue = CKRecordValue
public typealias RelationshipDeleteBehavior = CKReferenceAction


open class Record : Object {
    
    
    // MARK: - PUBLIC -
    
    
    // MARK: Initializers
    
    public convenience init(databaseScope: DatabaseScope) {
        
        self.init()
        
        self.databaseScope = databaseScope
        
        guard databaseScope != .shared else {
            fatalError("Root Records (aka Records without parents) cannot be saved to the shared Database.")
        }
        
        self.parent = nil
        
    }
    
    public convenience init(parent: Record) {
        
        self.init()
        
        self.databaseScope = parent.databaseScope
        
        self.parent = parent
        
    }
    
    
    // MARK: - Properties
    
    open fileprivate(set) dynamic var id: RecordID = UUID().uuidString
    
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
    
    
    // MARK: - Relationships
    
    public dynamic var parent: Record? = nil {
        
        willSet {
            
            
            
        }
        
    }
    
    
    internal let childrenRecordRelations = LinkingObjects(fromType: RecordRelation.self, property: "parent")
    public var children: Set<DynamicObject> {
        
        let database = Mist.dataCache.databaseForScope(databaseScope)
        var childrenToReturn: Set<DynamicObject> = []
        
        for childRecordRelation in childrenRecordRelations {
            
            let typeName = childRecordRelation.typeName
            let id = childRecordRelation.id
            
            guard let childRecord = database.dynamicFetch(recordOfTypeWithName: typeName, withId: id) else {
                continue
            }
            
            childrenToReturn.insert(childRecord)
            
        }
        
        return childrenToReturn
        
    }
    
    
    // MARK: - INTERNAL
    
    
    // MARK: - Initializers
    
    internal convenience init(realm: Realm, backingRemoteRecord: CKRecord, databaseScope: DatabaseScope, relatedRemoteRecords: Set<CKRecord>?=nil) {
        
        self.init()
        
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        backingRemoteRecord.encodeSystemFields(with: coder)
        coder.finishEncoding()
        self.encodedSystemFields = data as Data
        
        for key in backingRemoteRecord.allKeys() {
            
            if let objectForKey = backingRemoteRecord.object(forKey: key) {
                
                if let reference = objectForKey as? CKReference {
                    
                    guard let relatedRemoteRecords = relatedRemoteRecords, let referencedRecord = relatedRemoteRecords.filter({ $0.recordID == reference.recordID }).first else {
                        fatalError("You must provide all CKRecords referenced by backingRemoteRecord via the relatedRemoteRecords parameter.")
                    }
                    
                    let record: Record
                    
                    let filter: ((DynamicObject) -> Bool) = { dynamicObject in
                        
                        guard let id = dynamicObject.value(forKey: "id") as? String else {
                            fatalError("The DynamicObject instance does not have an id property: \(dynamicObject)")
                        }
                        
                        return id == referencedRecord.recordID.recordName
                        
                    }
                    
                    if let extantDynamicObject = realm.dynamicObjects(referencedRecord.recordType).filter(filter).first {
                        
                        let extantObject = extantDynamicObject as Object
                        
                        guard let extantRecord = extantObject as? Record else {
                            fatalError("Could not convert an Object instance to a Record instance: \(extantObject)")
                        }
                        
                        record = extantRecord
                        
                    } else {
                        
                        record = Record(realm: realm, backingRemoteRecord: referencedRecord, databaseScope: databaseScope, relatedRemoteRecords: relatedRemoteRecords)
                        
                    }
                    
                    setValue(record, forKey: key)
                    
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
    
    internal var databaseScope: DatabaseScope!
    
    
    // MARK: - Relationships
    
    internal dynamic var recordZone: RecordZone? = nil
    
    
    // MARK: - Functions
    
    internal func rootRecord() -> Record {
        
        guard let parent = parent else {
            return self
        }
        
        return parent.rootRecord()
        
    }
    
    internal func configureRecordZone(inRealm realm:Realm) {
        
        if let parent = self.parent {
            
            guard let parentRecordZone = parent.recordZone else {
                
                fatalError(
                    "You've called configureRecordZone on a Record whose parent has no record zone, which is not allowed. " +
                    "To avoid this, call configureRecordZone on a root record (one with no parent) first, then on its children."
                )
                
            }
            
            recordZone = parentRecordZone
            
        } else {
            
            let database = Mist.dataCache.databaseForScope(databaseScope)
            
            if databaseScope == .public {
                
                let defaultRecordZoneIdentifier = RecordZone.defaultCombinedIdentifier(forDatabase: database)
                
                guard let defaultRecordZone = realm.object(ofType: RecordZone.self, forPrimaryKey: defaultRecordZoneIdentifier) else {
                    fatalError("The public database should always have a default Record Zone.")
                }
                
                recordZone = defaultRecordZone
                
                
            } else {
                
                let containingRecordZone = RecordZone(zoneName: UUID().uuidString, database: database)
                realm.add(containingRecordZone)
                
                recordZone = containingRecordZone
                
            }
            
        }
        
    }
    
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
    
    override open class func primaryKey() -> String? {
        return "id"
    }
    
    override open class func ignoredProperties() -> [String] {
        return ["databaseScope"]
    }
    
}


