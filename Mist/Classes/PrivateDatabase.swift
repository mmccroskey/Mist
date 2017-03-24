//
//  PrivateDatabase.swift
//  Pods
//
//  Created by Matthew McCroskey on 3/23/17.
//
//

import Foundation

public class PrivateDatabase : NonPublicDatabase {

    init() { super.init(databaseScope: .private) }
    
}
