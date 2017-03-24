//
//  NonPublicDatabase.swift
//  RealmMist
//
//  Created by Matthew McCroskey on 2/5/17.
//  Copyright © 2017 Less But Better. All rights reserved.
//

import Foundation

class NonPublicDatabase : Database {
    
    
    // MARK: - Initializer
    
    init(databaseScope: DatabaseScope) {
        
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
        
        let fileName = "\(scopeName)+\(NonPublicDatabase.currentlyAuthenticatedUserID)"
        
        super.init(databaseScope: databaseScope, fileName: fileName)
        
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
}
