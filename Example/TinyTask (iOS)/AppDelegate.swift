//
//  AppDelegate.swift
//  Mist
//
//  Created by Matthew McCroskey on 03/18/2017.
//  Copyright (c) 2017 Matthew McCroskey. All rights reserved.
//

import UIKit
import Mist

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var token: Token? = nil

    func applicationDidBecomeActive(_ application: UIApplication) {
        
        let publicDb = PublicDatabase()
        
        token = publicDb.addNotificationBlock {
            
            print("Save completed on publicDb.")
            
            let titleIsGroceryList = NSPredicate(format: "title == %@", "Grocery List")
            if let savedGroceryList = publicDb.find(recordsOfType: TodoList.self, where: titleIsGroceryList).first {
                print("Here's the grocery list we saved: \(savedGroceryList)")
            }
            
        }
        
        let groceryList = TodoList()
        groceryList.title = "Grocery List"
        
        publicDb.write {
            
            publicDb.add(groceryList)
            
        }
        
    }

}

