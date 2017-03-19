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
    
    init(databaseScope: DatabaseScope, userID: RecordID?=nil) {
        
        guard type(of: self) != Database.self else {
            fatalError("Database is an abstract class and cannot be directly instantiated.")
        }
        
        self.databaseScope = databaseScope
        
        self.dispatchQueue = DispatchQueue(label: "com.Mist.database.record.\(databaseScope)")
        
        let fileName: String
        
        if databaseScope == .private || databaseScope == .shared {
            
            guard let userID = userID else {
                fatalError("Non-Public Databases must be created with a userID.")
            }
            
            let databaseScopeName: String
            
            switch databaseScope {
                
            case .private:
                databaseScopeName = "private"
                
            case .shared:
                databaseScopeName = "shared"
                
            default:
                fatalError("This code should only execute with a datascope of private or shared, but a different scope was provided: \(databaseScope)")
                
            }
            
            fileName = "\(userID)_\(databaseScopeName).realm"
            
        } else {
            
            fileName = "public.realm"
            
        }
        
        var config = Realm.Configuration()
        config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent(fileName)
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
    
    var defaultRecordZone: RecordZone {
        return realm.object(ofType: RecordZone.self, forPrimaryKey: "default")!
    }
    
    var recordZones: Results<RecordZone> {
        return realm.objects(RecordZone.self)
    }
    
    
    // MARK: - Notifications
    
    func addNotificationBlock(_ block: @escaping (() -> Void)) -> Token {
        
        return realm.addNotificationBlock({ (notification, realm) in
            block()
        })
        
    }
    
    
    // MARK: - Working with Records
    
    
    // MARK: Fetching
    
    func fetch<T: Record>(recordOfType type:T.Type, withId id:RecordID) -> T? {
        return self.fetchAll(recordsOfType: type).filter({ $0.id == id }).first
    }
    
    func fetch<T: Record>(recordsOfType type:T.Type, matchingIds ids:Set<RecordID>) -> Results<T> {
        
        let predicate = NSPredicate(format: "id IN %@", ids)
        let records = realm.objects(type).filter(predicate)
        
        return records
        
    }
    
    func fetchAll<T: Record>(recordsOfType type:T.Type) -> Results<T> {
        return realm.objects(type)
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
        return realm.objects(type).filter(predicate)
    }
    
    
    // MARK: Adding
    
    func addRecord(_ record:Record) {
        
        dispatchQueue.sync {
            
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
                            
                            // TODO: First, cascade-delete all the Records in this Record Zone

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
                    
                    // Ensure we have a default Record Zone for the Public Database
                    if databaseScope == .public {
                        
                        if writingRealm.object(ofType: RecordZone.self, forPrimaryKey: "default") == nil {
                            
                            let defaultRecordZone = RecordZone(zoneName: "default", database: self)
                            writingRealm.add(defaultRecordZone)
                            
                        }
                        
                    }
                    
                    for idOfRecordToDelete in self.idsOfRecordsToDeleteLocally {
                        
                        if let extantRecordToDelete = writingRealm.object(ofType: Record.self, forPrimaryKey: idOfRecordToDelete) {
                            
                            // TODO: Cascade delete this Record's children
                            
                            let recordZoneId = extantRecordToDelete.recordZone?.backingRecordZoneID
                            
                            writingRealm.delete(extantRecordToDelete)
                            self.idsOfRecordsWithUnpushedDeletions.insert(idOfRecordToDelete)
                            
                            // TODO: Get a reference to this Record's RecordZone
                            let filter: ((Record) -> Bool) = { (record)
                                
                                if let recordZoneId = record.recordZone?.
                                
                            }
                            if let recordZoneId = extantRecordToDelete.recordZone?.backingRecordZoneID,
                                let recordZone = writingRealm.object(ofType: RecordZone.self, forPrimaryKey: recordZoneId) {}
                            //                                let containedRecords = writingRealm.objects(Record.self).filter({  })
                            
                        }
                        
                    }
                    self.idsOfRecordsToDeleteLocally = []

                    for recordToModify in self.recordsToModifyLocally {
                        
                        let recordID = recordToModify.id
                        
                        let recordToSave: Record
                        if let extantRecord = writingRealm.object(ofType: Record.self, forPrimaryKey: recordID) {
                            recordToSave = extantRecord
                        } else {
                            
                            if let parent = recordToModify.parent {
                                
                                recordToSave = Record(parent: parent)
                                
                            } else {
                                
                                let containingRecordZone = RecordZone(zoneName: UUID().uuidString, database: self)
                                writingRealm.add(containingRecordZone)
                                
                                recordToSave = Record(databaseScope: recordToModify.databaseScope)
                                recordToSave.recordZone = containingRecordZone
                                
                            }
                            
                        }
                        
                        for key in recordToModify.allKeys() {

                            if let value = recordToModify.value(forKey: key) {
                                recordToSave.setValue(value, forKey: key)
                            }
                            
                        }
                        
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
    
    private let realm: Realm
    
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
