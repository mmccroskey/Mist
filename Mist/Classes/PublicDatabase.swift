//
//  PublicDatabase.swift
//  RealmMist
//
//  Created by Matthew McCroskey on 2/5/17.
//  Copyright © 2017 Less But Better. All rights reserved.
//

import Foundation

class PublicDatabase : Database {
    
    init() { super.init(databaseScope: .public) }
    
}
