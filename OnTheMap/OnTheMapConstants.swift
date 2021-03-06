//
//  OnTheMapConstants.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 16/11/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
////

import UIKit

extension OnTheMapClient {
    
    struct Constants {
        static let sessionUrl = "https://www.udacity.com/api/session"
        static let userUrl = "https://www.udacity.com/api/users"
        static let signUpUrl = "https://www.udacity.com/account/auth#!/signup"
        static let studentLocation = "https://parse.udacity.com/parse/classes/StudentLocation"
        static let studentLocationLimit = "limit="
        static let studentLocationOrder = "order="
        static let studentLocationDefault = "\(studentLocation)?\(studentLocationLimit)100&\(studentLocationOrder)-updatedAt"
        static let loggedInStudentLocation = "\(studentLocation)?where="
    }
    
}
