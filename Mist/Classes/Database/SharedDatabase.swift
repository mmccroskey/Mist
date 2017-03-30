//
//  SharedDatabase.swift
//  Pods
//
//  Created by Matthew McCroskey on 3/23/17.
//
//

import Foundation

public class SharedDatabase : NonPublicDatabase {
    
    init() throws { try super.init(databaseScope: .shared) }
    
}
