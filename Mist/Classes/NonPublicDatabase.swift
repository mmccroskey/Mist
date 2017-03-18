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
    
    init(databaseScope: DatabaseScope, userID: RecordID) {
        
        guard databaseScope != .public else {
            fatalError("Public Database instances must be created as instances of the class PublicDatabase.")
        }
        
        super.init(databaseScope: databaseScope, userID: userID)
        
    }
    
    
    // MARK: - Merging with Another Database
    
    // TODO: Properly implement this
    func merge(otherDatabase: NonPublicDatabase) -> NonPublicDatabase {
        return self
    }
    
}
