//
//  SerializableConfigurationStorage.swift
//  Pods
//
//  Created by Matthew McCroskey on 4/14/17.
//
//

import Foundation
import CloudKit

internal class SerializableConfigurationStorage {
    
    
    // MARK: - Database/ScopedDataStore Association
    
    internal static func scopedDataStoreId(forDatabaseWithScope databaseScope:DatabaseScope) -> String? {
        
        let key = scopedDataStoreKey(forDatabaseWithScope: databaseScope)
        
        guard let scopedDataStoreId = value(forKey: key) as? String else {
            return nil
        }
        
        return scopedDataStoreId
        
    }
    
    internal static func setScopedDataStoreId(_ scopedDataStoreId:String, forDatabaseWithScope databaseScope:DatabaseScope) {
        
        let key = scopedDataStoreKey(forDatabaseWithScope: databaseScope)
        setValue(scopedDataStoreId, forKey: key)
        
    }
    
    
    // MARK: - Server Change Tokens
    
    // MARK: Database
    
    internal static func serverChangeToken(forDatabaseWithScope databaseScope:DatabaseScope) -> CKServerChangeToken? {
        
        let databaseKey = serverChangeTokenKey(forDatabaseWithScope: databaseScope)
        return serverChangeToken(forKey: databaseKey)
        
    }
    
    internal static func setServerChangeToken(_ token:CKServerChangeToken, forDatabaseWithScope databaseScope:DatabaseScope) {
        
        let databaseKey = serverChangeTokenKey(forDatabaseWithScope: databaseScope)
        setServerChangeToken(token, forKey: databaseKey)
        
    }
    
    // MARK: Record Zone
    
    internal static func serverChangeToken(forRecordZoneWithID recordZoneID:RecordZoneID) -> CKServerChangeToken? {
        
        let recordZoneKey = serverChangeTokenKey(forRecordZoneWithID: recordZoneID)
        return serverChangeToken(forKey: recordZoneKey)
        
    }
    
    internal static func setServerChangeToken(_ token:CKServerChangeToken, forRecordZoneWithID recordZoneID:RecordZoneID) {
        
        let recordZoneKey = serverChangeTokenKey(forRecordZoneWithID: recordZoneID)
        setServerChangeToken(token, forKey: recordZoneKey)
        
    }
    
    // MARK: Private Helpers
    
    private static func serverChangeToken(forKey key:String) -> CKServerChangeToken? {
        
        guard let data = value(forKey: key) as? Data, let token = NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken else {
            return nil
        }
        
        return token
        
    }
    
    private static func setServerChangeToken(_ token:CKServerChangeToken?, forKey key:String) {
        
        if let token = token {
            
            let data = NSKeyedArchiver.archivedData(withRootObject: token)
            setValue(data, forKey: key)
            
        } else {
            
            setValue(nil, forKey: key)
            
        }
        
    }
    
    
    // MARK: - Key Helpers
    
    // MARK: Database Key Helpers
    
    private static func scopedDataStoreKey(forDatabaseWithScope databaseScope:DatabaseScope) -> String {
        
        let theDatabaseKey = databaseKey(forDatabaseWithScope: databaseScope)
        let dataStoreKey = "\(theDatabaseKey).scopedDataStore"
        
        return dataStoreKey
        
    }
    
    private static func serverChangeTokenKey(forDatabaseWithScope databaseScope:DatabaseScope) -> String {
        
        let theDatabaseKey = databaseKey(forDatabaseWithScope: databaseScope)
        let serverChangeTokenKey = "\(theDatabaseKey).serverChangeToken"
        
        return serverChangeTokenKey
        
    }
    
    private static func databaseKey(forDatabaseWithScope databaseScope:DatabaseScope) -> String {
        
        let scopeName: String
        switch databaseScope {
            
        case .public:
            scopeName = "public"
            
        case .private:
            scopeName = "private"
            
        case .shared:
            scopeName = "shared"
            
        }
        
        let databaseKey = "database.\(scopeName)"
        
        return mistScopedKey(fromKey: databaseKey)
        
    }
    
    // MARK: Record Zone Key Helpers
    
    private static func serverChangeTokenKey(forRecordZoneWithID recordZoneID:RecordZoneID) -> String {
        
        let recordZoneKey = "recordZone.\(recordZoneID).serverChangeToken"
        return mistScopedKey(fromKey :recordZoneKey)
        
    }
    
    private static func mistScopedKey(fromKey key:String) -> String {
        return "Mist.\(key)"
    }
    
    // MARK: - UserDefaults Interaction
    
    private static func value(forKey key:String) -> Any? {
        return UserDefaults.standard.value(forKey: key)
    }
    
    private static func setValue(_ value:Any?, forKey key:String) {
        
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
        
    }

    
}
