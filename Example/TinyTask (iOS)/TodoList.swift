//
//  TodoList.swift
//  RealmMist
//
//  Created by Matthew McCroskey on 2/22/17.
//  Copyright © 2017 Less But Better. All rights reserved.
//

import Foundation
import Mist



class TodoList : Record {
    
    
    // MARK: - Properties
    
    dynamic var title: String = ""
    dynamic var isArchived: Bool = false
    
    
    // MARK: - Mist Helper Functions
    
    override func propertyKeys() -> Set<String> {
        return Set(["title", "isArchived"])
    }
    
}


