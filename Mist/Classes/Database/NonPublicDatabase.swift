//
//  NonPublicDatabase.swift
//  RealmMist
//
//  Created by Matthew McCroskey on 2/5/17.
//  Copyright © 2017 Less But Better. All rights reserved.
//

import Foundation

public class NonPublicDatabase : Database {
    
    
    // MARK: - Initializer
    
    init(databaseScope: DatabaseScope) throws {
        
        
        guard let currentUser = Mist.currentUser else {
            throw MistError.noUserExists
        }

        
        guard databaseScope != .public else {
            fatalError("Public Database instances must be created as instances of the class PublicDatabase.")
        }
        
        let scopeName: String
        switch databaseScope {
            
        case .public:
            fatalError("Public Database instances must be created as instances of the class PublicDatabase.")
            
        case .private:
            scopeName = "private"
            
        case .shared:
            scopeName = "shared"
            
        }
        
        let fileName = "\(scopeName)+\(currentUser.id)"
        
        try super.init(databaseScope: databaseScope, fileName: fileName)
        
        // We have to put this down here (after call to super.init) since it uses self
        guard (type(of: self) != Database.self) && (type(of: self) != NonPublicDatabase.self) else {
            fatalError("NonPublicDatabase is an abstract class and cannot be directly instantiated. Please use PrivateDatabase or SharedDatabase.")
        }
        
    }
    
    
    // MARK: - Merging with Another Database
    
    // TODO: Properly implement this
    func merge(otherDatabase: NonPublicDatabase) -> NonPublicDatabase {
        return self
    }
    
    
    // MARK: - Adjusting When the Current User Changes
    
    static private var currentlyAuthenticatedUserID: RecordID {
        
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
    
    
    // TODO: Properly implement this
    /*
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
 */

    
}
