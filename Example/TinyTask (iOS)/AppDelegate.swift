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
                
                let todoListIsGroceryList = NSPredicate(format: "todoList == %@", savedGroceryList)
                let savedTodos = publicDb.find(recordsOfType: Todo.self, where: todoListIsGroceryList)
                
                print("Here are the items in the grocery list: \(savedTodos)")
                
            }
            
        }
        
        let groceryList = TodoList()
        groceryList.title = "Grocery List"
        
        let eggs = Todo()
        eggs.title = "Eggs"
        eggs.todoList = groceryList
        
        let milk = Todo()
        milk.title = "Milk"
        milk.todoList = groceryList
        
        let bread = Todo()
        bread.title = "Bread"
        bread.todoList = groceryList
        
        publicDb.write {
            
            publicDb.add(groceryList)
            publicDb.add(eggs)
            publicDb.add(milk)
            publicDb.add(bread)
            
        }
        
    }

}

