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
        
        /*
        let groceryList = TodoList(databaseScope: .private)
        groceryList.title = "Grocery List"
        print("Here's the grocery list: \(groceryList)")
        
        let milk = Todo(parent: groceryList)
        milk.parent = groceryList
        
        
        Mist.write {
            
            Mist.add(groceryList)
            
        }
        */
        
        token = Mist.addNotificationBlock(forScope: .private) {
            
            guard let fetchedGroceryList = Mist.fetchAll(recordsOfType: TodoList.self, from: .private).first else {
                
                print("Grocery List has been deleted!")
                return
                
            }
            
            print("Here's the grocery list! \(fetchedGroceryList)")
            
            
            let incompleteTodos = Mist.find(recordsOfType: Todo.self, filteredBy: { $0.isCompleted == false }, within: .private)
            print("Here are the incomplete Todos: \(incompleteTodos)")
            
            guard let fetchedMilk = incompleteTodos.filter({ $0.title == "Milk" }).first else {
                
                print("Milk has been deleted!")
                return
                
            }
            
            print("Here's the milk todo: \(fetchedMilk)")
            
        }
        
        print("About to start creating Records...")
        
        let groceryList = TodoList(databaseScope: .private)
        groceryList.title = "Grocery List"
        
        print("Here's the groceryList we just created: \(groceryList)")
        
        let eggs = Todo(parent: groceryList)
        eggs.title = "Eggs"
        
        print("Here's the eggs Todo we just created: \(eggs)")
        
        let milk = Todo(parent: groceryList)
        milk.title = "Milk"
        
        print("Here's the milk Todo we just created: \(milk)")
        
        let bread = Todo(parent: groceryList)
        bread.title = "Bread"
        
        print("Here's the bread Todo we just created: \(bread)")
        
        print("About to write...")
        
        Mist.write {
            
            print("Inside the Mist write block...")
            
            let records: Set<Record> = [groceryList, eggs, milk, bread]
            Mist.add(records)
            
        }
        
    }

}

