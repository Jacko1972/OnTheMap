//
//  OnTheMapClass.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 19/12/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//
import Foundation

class OnTheMapClass {

    static let sharedInstance = OnTheMapClass()
    
    private init(){}
    
    var postSession: PostSession? = nil
    var studentLocations: [StudentInformation] = [StudentInformation]()
    var hasExistingLocationStored: Bool = false
    var studentInformationObject: StudentInformation?
    var studentPublicInformation: PublicUserData?
    
}
