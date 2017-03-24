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

internal enum ObjectChangeType {
    case addition
    case removal
}

internal struct ObjectChange {
    
    let changeType: ObjectChangeType
    let object: Object
    
}

internal class Database {
    
    
    // MARK: - Initializers
    
    init(databaseScope: DatabaseScope, fileName: String) {
        
        guard type(of: self) != Database.self else {
            fatalError("Database is an abstract class and cannot be directly instantiated.")
        }
        
        self.databaseScope = databaseScope
        
        self.dispatchQueue = DispatchQueue(label: "com.Mist.database.\(databaseScope)")
        
        let fileNameWithFileType = "\(fileName).realm"
        
        var config = Realm.Configuration()
        config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent(fileNameWithFileType)
        self.realmConfiguration = config
        
        DispatchQueue.main.sync {
            
            do {
                
                realm = try Realm(configuration: config)
                
            } catch let error {
                
                fatalError("\(error)")
                
            }
            
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
    
    /*
    var recordZones: Results<RecordZone> {
        
        let recordZones: Results<RecordZone>
        
        DispatchQueue.main.sync {
            recordZones = realm.objects(RecordZone.self)
        }
        
        return recordZones
        
    }
    */
    
    // MARK: - Notifications
    
    func addNotificationBlock(_ block: @escaping (() -> Void)) -> Token {
        
        var token: Token? = nil
        
        DispatchQueue.main.sync {
            
            token = realm.addNotificationBlock({ (notification, realm) in
                block()
            })
            
        }
        
        return token!
        
    }
    
    
    // MARK: - Working with Record Zones
    
    
    func addRecordZone(_ recordZone:RecordZone) {
        
        dispatchQueue.sync {
            
            if !(idsOfRecordZonesToDeleteLocally.contains(recordZone.backingRecordZoneID)) {
                recordZonesToModifyLocally.insert(recordZone)
            }
            
        }
        
    }
    
    func removeRecordZone(_ recordZone:RecordZone) {
        
        dispatchQueue.sync {
            
            do {
                
                let tempRealm = try Realm(configuration: realmConfiguration)

                let predicate = NSPredicate(format: "recordZone == %@", recordZone)
                let containedRecords = tempRealm.objects(Record.self).filter(predicate)
                let containedRecordsIds = containedRecords.map({ $0.id })
                
                var recordsToRemove: [Record] = []
                for record in recordsToModifyLocally {
                    
                    if containedRecordsIds.contains(record.id) {
                        recordsToRemove.append(record)
                    }
                    
                }
                recordsToModifyLocally = recordsToModifyLocally.subtracting(Set(recordsToRemove))
                
                idsOfRecordsToDeleteLocally = idsOfRecordsToDeleteLocally.subtracting(Set(containedRecordsIds))
                
            } catch let error {
                fatalError("\(error)")
            }
            
            
            recordZonesToModifyLocally.remove(recordZone)
            idsOfRecordZonesToDeleteLocally.insert(recordZone.backingRecordZoneID)
            
        }
        
    }
    
    
    // MARK: - Working with Records
    
    
    // MARK: Fetching
    
    func dynamicFetch(recordOfTypeWithName typeName:String, withId id:RecordID) -> DynamicObject? {
        
        var dynamicObject: DynamicObject? = nil
        
        DispatchQueue.main.sync {
            dynamicObject = realm.dynamicObject(ofType: typeName, forPrimaryKey: id)
        }
        
        return dynamicObject
        
    }
    
    func fetch<T: Record>(recordOfType type:T.Type, withId id:RecordID) -> T? {
        return fetch(recordsOfType: type, matchingIds: Set([id])).first
    }
    
    func fetch<T: Record>(recordsOfType type:T.Type, matchingIds ids:Set<RecordID>) -> Results<T> {
        
        let predicate = NSPredicate(format: "id IN %@", ids)
        let records = fetchAll(recordsOfType: type).filter(predicate)
        
        return records
        
    }
    
    func fetchAll<T: Record>(recordsOfType type:T.Type) -> Results<T> {
        
        var results: Results<T>? = nil
        
        DispatchQueue.main.sync {
            results = realm.objects(type)
        }
        
        return results!
        
    }
    
    
    // MARK: Finding
    
    func find<T: Record>(recordsOfType type:T.Type, filteredBy filter: @escaping ((T) -> Bool)) -> Results<T> {
        
        let predicate = NSPredicate { (object, parameters) -> Bool in
            
            guard let record = object as? T else {
                fatalError()
            }
            
            return filter(record)
            
        }
        
        return realm.objects(type).filter(predicate)
        
    }
    
    func find<T: Record>(recordsOfType type:T.Type, where predicate:NSPredicate) -> Results<T> {
        
        var results: Results<T>? = nil
        
        DispatchQueue.main.sync {
            results = realm.objects(type).filter(predicate)
        }
        
        return results!
        
    }
    
    
    // MARK: Adding
    
    func addRecord(_ record:Record) {
        
        print("Inside addRecord but outside the dispatchQueue's sync call...")
        
        dispatchQueue.sync {
            
            print("Inside addRecord's dispatchQueue's sync call...")
            
            if !(idsOfRecordsToDeleteLocally.contains(record.id)) {
                recordsToModifyLocally.insert(record)
            }
            
        }
        
    }
    
    
    // MARK: Removing
    
    func removeRecord(_ record:Record) {
        
        dispatchQueue.sync {
            
            recordsToModifyLocally.remove(record)
            idsOfRecordsToDeleteLocally.insert(record.id)
            
        }
        
    }
    
    
    // MARK: Processing Changes
    
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
    
    
    // MARK: - Private Properties
    
    private var realm: Realm!
    
    private let databaseScope: DatabaseScope
    
    private let dispatchQueue: DispatchQueue!
    
    private var idsOfRecordZonesToDeleteLocally: Set<CKRecordZoneID> = []
    private var recordZonesToModifyLocally: Set<RecordZone> = []
    
    private var idsOfRecordsToDeleteLocally: Set<RecordID> = []
    private var recordsToModifyLocally: Set<Record> = []
    
    private var idsOfRecordZonesWithUnpushedChanges: Set<CKRecordZoneID> = []
    private var idsOfRecordZonesWithUnpushedDeletions: Set<CKRecordZoneID> = []
    
    private var idsOfRecordsWithUnpushedChanges: Set<RecordID> = []
    private var idsOfRecordsWithUnpushedDeletions: Set<RecordID> = []
    
    private let realmConfiguration: Realm.Configuration
    
}
