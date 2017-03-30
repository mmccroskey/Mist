//
//  Mist.swift
//  RealmMist
//
//  Created by Matthew McCroskey on 2/4/17.
//  Copyright © 2017 Less But Better. All rights reserved.
//

import Foundation
import RealmSwift

public enum MistError : Error {
    
    case noUserExists
    
}

public class Mist {
    
    public static var currentUser: User? = User()
}
