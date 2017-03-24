//
//  Todo.swift
//  RealmMist
//
//  Created by Matthew McCroskey on 2/16/17.
//  Copyright © 2017 Less But Better. All rights reserved.
//

import Foundation
import Mist


class Todo : Record {
    
    
    // MARK: - Properties
    
    dynamic var title: String = ""
    dynamic var isCompleted: Bool = false
    
    
    // MARK: - Relationships
    
    dynamic var todoList: TodoList?
    
    
    // MARK: - Mist Helper Functions
    
    override func propertyKeys() -> Set<String> {
        return Set(["title", "isCompleted"])
    }
    
    override func relationshipKeys() -> Set<String> {
        return Set(["todoList"])
    }
    
}



