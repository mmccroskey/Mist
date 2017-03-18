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

    func applicationDidBecomeActive(_ application: UIApplication) {
        
        let messenger = Messenger("Hello World!")
        messenger.printMessage()
        
    }

}

