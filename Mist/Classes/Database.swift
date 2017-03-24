//
//  Database.swift
//  RealmMist
//
//  Created by Matthew McCroskey on 2/4/17.
//  Copyright © 2017 Less But Better. All rights reserved.
//

import Foundation
import RealmSwift
import CloudKit

public typealias DatabaseScope = CKDatabaseScope
public typealias Token = NotificationToken

public class Database {
    
    
    // MARK: - Initializers
    
    internal init(databaseScope: DatabaseScope, fileName: String) {
        
        guard type(of: self) != Database.self else {
            fatalError("Database is an abstract class and cannot be directly instantiated. Please use PublicDatabase, PrivateDatabase, or SharedDatabase.")
        }
        
        self.databaseScope = databaseScope
        
        self.dispatchQueue = DispatchQueue(label: "com.Mist.database.\(databaseScope)")
        
        let fileNameWithFileType = "\(fileName).realm"
        var config = Realm.Configuration()
        config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent(fileNameWithFileType)
        self.realmConfiguration = config
        
        do {
            realm = try Realm(configuration: config)
        } catch let error {
            fatalError("\(error)")
        }
        
    }
    
    
    // MARK: - Properties
    
    var scopeName: String {
        
        switch databaseScope {
            
        case .public:
            return "public"
            
        case .private:
            return "private"
            
        case .shared:
            return "shared"
        
        }
        
    }
    
    // MARK: - Notifications
    
    public func addNotificationBlock(_ block: @escaping (() -> Void)) -> Token {
        
        return realm.addNotificationBlock({ (notification, realm) in
            block()
        })
        
    }
    
    
    // MARK: - Working with Record Zones
    
    
    internal func addRecordZone(_ recordZone:RecordZone) {
        
        if !(idsOfRecordZonesWithUnpushedDeletions.contains(recordZone.backingRecordZoneID)) {
            
            realm.add(recordZone)
            recordZonesWithUnpushedChanges.insert(recordZone)
            
        }
        
    }
    
    internal func removeRecordZone(_ recordZone:RecordZone) {
        
        // TODO: This won't work because none of the Records will have the class Record
        let predicate = NSPredicate(format: "recordZone == %@", recordZone)
        let containedRecords = realm.objects(Record.self).filter(predicate)
        let containedRecordsIds = containedRecords.map({ $0.id })
        
        var recordsToRemove: [Record] = []
        for record in recordsWithUnpushedChanges {
            
            if containedRecordsIds.contains(record.id) {
                recordsToRemove.append(record)
            }
            
        }
        
        recordsWithUnpushedChanges = recordsWithUnpushedChanges.subtracting(recordsToRemove)
        idsOfRecordsWithUnpushedDeletions = idsOfRecordsWithUnpushedDeletions.subtracting(Set(containedRecordsIds))
        
        recordZonesWithUnpushedChanges.remove(recordZone)
        idsOfRecordZonesWithUnpushedDeletions.insert(recordZone.backingRecordZoneID)
        
        realm.delete(recordZone)
        
    }
    
    
    // MARK: - Working with Records
    
    
    // MARK: Fetching
    
    internal func dynamicFetch(recordOfTypeWithName typeName:String, withId id:RecordID) -> DynamicObject? {
        return realm.dynamicObject(ofType: typeName, forPrimaryKey: id)
    }
    
    public func fetch<T: Record>(recordOfType type:T.Type, withId id:RecordID) -> T? {
        return fetch(recordsOfType: type, matchingIds: Set([id])).first
    }
    
    public func fetch<T: Record>(recordsOfType type:T.Type, matchingIds ids:Set<RecordID>) -> Results<T> {
        
        let predicate = NSPredicate(format: "id IN %@", ids)
        let records = fetchAll(recordsOfType: type).filter(predicate)
        
        return records
        
    }
    
    public func fetchAll<T: Record>(recordsOfType type:T.Type) -> Results<T> {
        return realm.objects(type)
    }
    
    
    // MARK: Finding
    
    /*
    public func find<T: Record>(recordsOfType type:T.Type, filteredBy filter: @escaping ((T) -> Bool)) -> Results<T> {
        
        let predicate = NSPredicate { (object, parameters) -> Bool in
            
            guard let record = object as? T else {
                fatalError()
            }
            
            return filter(record)
            
        }
        
        return realm.objects(type).filter(predicate)
        
    }
 */
    
    public func find<T: Record>(recordsOfType type:T.Type, where predicate:NSPredicate) -> Results<T> {
        return realm.objects(type).filter(predicate)
    }
    
    
    // MARK: Adding
    
    public func add(_ record:Record) {
        
        if !(idsOfRecordsWithUnpushedDeletions.contains(record.id)) {
            
            
            
            realm.add(record)
            recordsWithUnpushedChanges.insert(record)
            
        }
        
    }
    
    
    // MARK: Removing
    
    public func delete(_ record:Record) {
        
        recordsWithUnpushedChanges.remove(record)
        idsOfRecordsWithUnpushedDeletions.insert(record.id)
        
        realm.delete(record)
        
    }
    
    
    // MARK: Saving
    
    public func write(_ block:(() -> Void)) {
        
        do {
            
            try realm.write {
                
                block()
                
                // TODO: Sync to CloudKit
                
            }
            
        } catch let error {
            fatalError("\(error)")
        }
        
    }
    
    
    // MARK: Processing Changes
    
    /*
    func processRecordChanges() {
        
        dispatchQueue.sync {
            
            do {
                
                let writingRealm = try Realm(configuration: self.realmConfiguration)
                
                try writingRealm.write {
                    
                    
                    // MARK: Record Zone Changes
                    
                    for idOfRecordZoneToDelete in self.idsOfRecordZonesToDeleteLocally {
                        
                        if let extantRecordZoneToDelete = writingRealm.object(ofType: RecordZone.self, forPrimaryKey: idOfRecordZoneToDelete) {
                            
                            let predicate = NSPredicate(format: "recordZone == %@", extantRecordZoneToDelete)
                            let containedRecords = writingRealm.objects(Record.self).filter(predicate)
                            writingRealm.delete(containedRecords)

                            writingRealm.delete(extantRecordZoneToDelete)
                            self.idsOfRecordZonesWithUnpushedDeletions.insert(idOfRecordZoneToDelete)

                        }

                    }
                    self.idsOfRecordZonesToDeleteLocally = []

                    for recordZoneToModify in self.recordZonesToModifyLocally {

                        let recordZoneID = recordZoneToModify.combinedIdentifier

                        let recordZoneToSave: RecordZone
                        if let extantRecordZone = writingRealm.object(ofType: RecordZone.self, forPrimaryKey: recordZoneID) {
                            recordZoneToSave = extantRecordZone
                        } else {
                            recordZoneToSave = RecordZone(zoneName: recordZoneToModify.zoneName, database: recordZoneToModify.database)
                        }
                        
                        recordZoneToSave.zoneName = recordZoneToModify.zoneName
                        recordZoneToSave.ownerName = recordZoneToModify.ownerName
                        
                        writingRealm.add(recordZoneToSave)
                        self.idsOfRecordZonesWithUnpushedChanges.insert(recordZoneToModify.backingRecordZoneID)
                        
                    }
                    self.recordZonesToModifyLocally = []
                    
                    
                    // MARK: Record Changes
                    
                    func performCascadingAction(onRecord record:Record, action:((Record) -> Void)) {
                        
                        let predicate = NSPredicate(format: "parent.id == %@", record.id)
                        let children = writingRealm.objects(Record.self).filter(predicate)
                        
                        for child in children {
                            performCascadingAction(onRecord: child, action: action)
                        }
                        
                        action(record)
                        
                    }
                    
                    // Ensure we have a default Record Zone for the Public Database
                    if databaseScope == .public {
                        
                        let defaultCombinedIdentifier = RecordZone.defaultCombinedIdentifier(forDatabase: self)
                        
                        if writingRealm.object(ofType: RecordZone.self, forPrimaryKey: defaultCombinedIdentifier) == nil {
                            
                            let defaultRecordZone = RecordZone(zoneName: defaultCombinedIdentifier, database: self)
                            writingRealm.add(defaultRecordZone)
                            
                        }
                        
                    }
                    
                    for idOfRecordToDelete in self.idsOfRecordsToDeleteLocally {
                        
                        if let extantRecordToDelete = writingRealm.object(ofType: Record.self, forPrimaryKey: idOfRecordToDelete) {
                            
                            let recordZoneId = extantRecordToDelete.recordZone?.combinedIdentifier
                            
                            performCascadingAction(onRecord: extantRecordToDelete) { record in
                                
                                writingRealm.delete(record)
                                self.idsOfRecordsWithUnpushedDeletions.insert(record.id)
                                
                            }
                            
                            // Delete the parent Record Zone too if it's empty
                            guard let recordZone = writingRealm.object(ofType: RecordZone.self, forPrimaryKey: recordZoneId) else { continue }
                            let predicate = NSPredicate(format: "recordZone == %@", recordZone)
                            let recordsInRecordZone = writingRealm.objects(Record.self).filter(predicate)
                            let recordZoneHasNoRecords = (recordsInRecordZone.count == 0)
                            if recordZoneHasNoRecords {
                                writingRealm.delete(recordZone)
                            }
                            
                        }
                        
                    }
                    self.idsOfRecordsToDeleteLocally = []

                    for recordToModify in self.recordsToModifyLocally {
                        
                        // Ensure that the full tree of records that includes this record has their Record Zones set
                        performCascadingAction(onRecord: recordToModify.rootRecord()) { $0.configureRecordZone(inRealm: writingRealm) }
                        
                        let recordID = recordToModify.id
                        
                        let classNameOfRecordToModify = String(describing: type(of: recordToModify))
                        let recordToSave = writingRealm.dynamicCreate(classNameOfRecordToModify, value: recordToModify, update: true)
                        
                        /*
                        if let extantRecord = writingRealm.dynamicObject(ofType: classNameOfRecordToModify, forPrimaryKey: recordID) {
                            
                            recordToSave = extantRecord
                            
                        } else {
                            
                            
                            
                            recordToSave = writingRealm.dynamicCreate(classNameOfRecordToModify, value: recordToModify, update: true)
                            
                            if let parent = recordToModify.parent {
                                recordToSave = Record(parent: parent)
                            } else {
                                recordToSave = Record(databaseScope: recordToModify.databaseScope)
                            }
                            
                        }
                        
                        for key in recordToModify.allKeys() {
                            
                            if let value = recordToModify.value(forKeyPath: key) {
                                recordToSave.setValue(value, forKeyPath: key)
                            }
                            
                        }
                         */
                        
                        writingRealm.add(recordToSave)
                        self.idsOfRecordsWithUnpushedChanges.insert(recordID)
                        
                    }
                    self.recordsToModifyLocally = []
                    
                }
                
            } catch let error {
                fatalError("Could not write changes to local cache due to error: \(error)")
            }
            
        }
        
    }
 */
    
    
    // MARK: - Private Properties
    
    internal var realm: Realm!
    
    internal let databaseScope: DatabaseScope
    
    private let dispatchQueue: DispatchQueue!
    
    private var recordZonesWithUnpushedChanges: Set<RecordZone> = []
    private var idsOfRecordZonesWithUnpushedDeletions: Set<CKRecordZoneID> = []
    
    private var recordsWithUnpushedChanges: Set<Record> = []
    private var idsOfRecordsWithUnpushedDeletions: Set<RecordID> = []
    
    private let realmConfiguration: Realm.Configuration
    
}
