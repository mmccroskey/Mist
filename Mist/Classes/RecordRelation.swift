//
//  RecordRelation.swift
//  Pods
//
//  Created by Matthew McCroskey on 3/22/17.
//
//

import Foundation
import RealmSwift

class RecordRelation : Object {
    
    dynamic var parent: Record? = nil
    
    dynamic var typeName: String = ""
    dynamic var id: String = ""
    
}
