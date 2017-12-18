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

struct StudentInformation:  Decodable, Comparable {
    static func <(lhs: StudentInformation, rhs: StudentInformation) -> Bool {
        return lhs.createdAt! > rhs.createdAt!
    }
    
    static func ==(lhs: StudentInformation, rhs: StudentInformation) -> Bool {
        return lhs.firstName == rhs.firstName && lhs.lastName == rhs.lastName
    }
    
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

struct UniqueKeyJson: Codable {
    var uniqueKey: String
}

struct PublicUserJson: Codable {
    let user: PublicUserData
}

struct PublicUserData: Codable {
    let first_name: String?
    let last_name: String?
    let key: String?
}

struct CompletedPostOfUserLocationResponse: Decodable {
    let createdAt: String?
    let objectId: String?
}
struct CompletedPutOfUserLocationResponse: Decodable {
    let updatedAt: String?
}


