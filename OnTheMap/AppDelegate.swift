//
//  AppDelegate.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 13/11/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    var postSession: PostSession? = nil
    var studentLocations: [StudentInformation] = [StudentInformation]()
    var hasExistingLocationStored: Bool = false
    var studentInformationObject: StudentInformation?
    var studentPublicInformation: PublicUserData?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        OnTheMapClient.sharedInstance().deleteSessionWithUdacityApi()
    }
}

