//
//  DataStructures.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 13/11/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import UIKit

struct StudentLocations: Decodable {
    let results: [StudentInformation]
}

struct StudentInformation:  Decodable {
    
    let createdAt: String?
    let firstName: String?
    let lastName: String?
    let latitude: Double?
    let longitude: Double?
    let mapString: String?
    let mediaURL: String?
    let objectId: String?
    let uniqueKey: String?
    let updatedAt: String?
    
    func getFullName() -> String {
        return firstName! + " " + lastName!
    }
}

struct PostSession: Decodable {
    
    let account: Account
    let session: Session
}
struct Session: Decodable {

    let id: String // Session ID
    let expiration: String // Session Expiry Date
}

struct Account: Decodable {
    
    let registered: Bool // Is user registered
    let key: String // User key
}
