//
//  DataStructures.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 13/11/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import UIKit

struct StudentInformation:  Decodable {
    
    let createdAt: Date
    let firstName: String
    let lastName: String
    let latitude: Float
    let longitude: Float
    let mapString: String
    let mediaURL: String
    let objectId: String
    let uniqueKey: String
    let updatedAt: Date
}

struct PostSession: Decodable {
    
    let account: Account
    let session: Session
}
struct Session: Decodable {

    let id: String // Session ID
    let expiration: Date // Session Expiry Date
}

struct Account: Decodable {
    
    let registered: Bool // Is user registered
    let key: String // User key
}
