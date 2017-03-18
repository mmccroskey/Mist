//
//  Mist.swift
//  RealmMist
//
//  Created by Matthew McCroskey on 2/4/17.
//  Copyright © 2017 Less But Better. All rights reserved.
//

import Foundation
import RealmSwift

public class Mist {
    
    
    // MARK: - Fetching Items
    
    public static func fetch<T: Record>(recordOfType type:T.Type, withId id:RecordID, from:DatabaseScope) -> T? {
        
        let database = Mist.dataCache.databaseForScope(from)
        return database.fetch(recordOfType: type, withId: id)
        
    }
    
    public static func fetch<T: Record>(recordsOfType type:T.Type, matchingIds ids:Set<RecordID>, from:DatabaseScope) -> Results<T> {
        
        let database = Mist.dataCache.databaseForScope(from)
        return database.fetch(recordsOfType: type, matchingIds: ids)
        
    }
    
    public static func fetchAll<T: Record>(recordsOfType type:T.Type, from:DatabaseScope) -> Results<T> {
        
        let database = Mist.dataCache.databaseForScope(from)
        return database.fetchAll(recordsOfType: type)
        
    }
    
    
    // MARK: - Finding Items
    
    public static func find<T: Record>(recordsOfType type:T.Type, filteredBy filter: @escaping ((T) -> Bool), within:DatabaseScope) -> Results<T> {
        
        let database = Mist.dataCache.databaseForScope(within)
        return database.find(recordsOfType: type, filteredBy: filter)
        
    }
    
    public static func find<T: Record>(recordsOfType type:T.Type, where predicate:NSPredicate, within:DatabaseScope) -> Results<T> {
        
        let database = Mist.dataCache.databaseForScope(within)
        return database.find(recordsOfType: type, where: predicate)
        
    }
    
    
    // MARK: - Modifying Items
    
    public static func add(_ record:Record) {
        add(Set([record]))
    }
    
    public static func add(_ records:Set<Record>) {
        modify(records, withChangeType: .addition)
    }
    
    public static func remove(_ record:Record) {
        remove(Set([record]))
    }
    
    public static func remove(_ records:Set<Record>) {
        modify(records, withChangeType: .removal)
    }
    
    public static func write(_ closure: @escaping (() -> Void)) {
        
        dispatchQueue.async {
            
            closure()
            
            for database in dataCache.databases {
                database.processRecordChanges()
            }
            
        }
        
    }
    
    
    // MARK: - Subscribing to Changes
    
    public static func addNotificationBlock(forScope scope:DatabaseScope, block: @escaping (() -> Void)) -> Token {
        
        let database = Mist.dataCache.databaseForScope(scope)
        return database.addNotificationBlock(block)
        
    }
    
    
    // MARK: - Internal Properties
    
    internal static let dataCache = DataCache()
    
    
    // MARK: - Private Properties
    
    private static let dispatchQueue = DispatchQueue(label: "com.Mist.userInteraction")
    
    
    // MARK: - Private Functions
    
    private static func modify(_ records:Set<Record>, withChangeType changeType:ObjectChangeType) {
        
        for record in records {
            
            guard let database = record.recordZone?.database else {
                fatalError("Every Record should have a Record Zone, which should have a Database.")
            }
            
            switch changeType {
                
            case .addition:
                database.addRecord(record)
                
            case .removal:
                database.removeRecord(record)
            
            }
            
        }
        
    }
    
}
