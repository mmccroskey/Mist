//
//  Messenger.swift
//  Pods
//
//  Created by Matthew McCroskey on 3/18/17.
//
//

import Foundation

public class Messenger {
    
    let message: String
    
    public init(_ message:String) {
        self.message = message
    }
    
    public func printMessage() {
        print(message)
    }
    
}
