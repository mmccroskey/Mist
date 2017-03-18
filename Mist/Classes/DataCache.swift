//
//  DataCache.swift
//  Mist
//
//  Created by Matthew McCroskey on 1/24/17.
//  Copyright © 2017 Less But Better. All rights reserved.
//

import Foundation
import CloudKit


public enum CacheRetentionBehavior {
    case none
    case unpushedChanges
    case all
}


internal class DataCache {
    
    
    // MARK: - Initializer
    
    init() {
        
        self.updateUserDatabases(withUserID: self.currentlyAuthenticatedUserID)
        databases = [self.publicDatabase, self.privateDatabase, self.sharedDatabase]
    
    }
    
    
    // MARK: - Internal Properties
    
    var cacheRetentionBehavior: CacheRetentionBehavior = .all
    var databases: [Database] = []
    
    
    // MARK: - Internal Functions
    
    func updateCurrentUserCache(forUserID userID:RecordID) {
        
        // Prep for merging temp data if appropriate
        let usingTempCache = (self.currentlyAuthenticatedUserID == "temporaryUserCache")
        let tempPrivateDatabase: NonPublicDatabase? = usingTempCache ? self.privateDatabase : nil
        let tempSharedDatabase: NonPublicDatabase? = usingTempCache ? self.sharedDatabase : nil
        
        // Point our non-public databases to the Realms for the new User
        self.updateUserDatabases(withUserID: userID)
        
        // Merge temp data into these databases if appropriate
        if let tempPrivateDatabase = tempPrivateDatabase, let tempSharedDatabase = tempSharedDatabase {
            
            self.privateDatabase = self.privateDatabase.merge(otherDatabase: tempPrivateDatabase)
            self.sharedDatabase = self.sharedDatabase.merge(otherDatabase: tempSharedDatabase)
            
        }
        
        // Update our stored User ID
        self.currentlyAuthenticatedUserID = userID
        
    }
    
    func databaseForScope(_ scope:DatabaseScope) -> Database {
        
        switch scope {
            
        case .public:
            return self.publicDatabase
            
        case .private:
            return self.privateDatabase
            
        case .shared:
            return self.sharedDatabase
            
        }
        
    }
    
    
    // MARK: - Private Properties
    
    private let publicDatabase: Database = PublicDatabase()
    private var privateDatabase: NonPublicDatabase!
    private var sharedDatabase: NonPublicDatabase!
    
    private var currentlyAuthenticatedUserID: RecordID {
        
        get {
            
            if let userID = UserDefaults.standard.value(forKey: "Mist.currentlyAuthenticatedUserID") as? RecordID {
                
                return userID
                
            } else {
                
                let userID = "temporaryUserCache"
                UserDefaults.standard.set(userID, forKey: "Mist.currentlyAuthenticatedUserID")
                UserDefaults.standard.synchronize()
                
                return userID
                
            }
            
        }
        
        set {
            
            UserDefaults.standard.set(newValue, forKey: "Mist.currentlyAuthenticatedUserID")
            UserDefaults.standard.synchronize()
            
        }
        
    }
    
    
    // MARK: - Private Functions
    
    private func updateUserDatabases(withUserID userID:RecordID) {
        
        self.privateDatabase = NonPublicDatabase(databaseScope: .private, userID: userID)
        self.sharedDatabase = NonPublicDatabase(databaseScope: .shared, userID: userID)
        
    }
    
}
