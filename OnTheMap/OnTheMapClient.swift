//
//  OnTheMapClient.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 16/11/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//
import UIKit
import Foundation
import CoreLocation
import MapKit


class OnTheMapClient: NSObject {
    
    static let instance = OnTheMapClient()
    
    func authenticateWithUdacityApi(_ username: String, password: String, completionHandlerForAuth: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        var request = URLRequest(url: URL(string: Constants.sessionUrl)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{\"udacity\": {\"username\": \"\(username)\", \"password\": \"\(password)\"}}".data(using: .utf8)
        let session = URLSession.shared
        
        let task = session.dataTask(with: request) { data, response, error in
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForAuth(false, NSError(domain: "Authenticate With Udacity Api", code: 1, userInfo: userInfo))
            }
            if error != nil {
                sendError("An error was reported: \(String(describing: error!.localizedDescription))")
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                let code = (response as? HTTPURLResponse)?.statusCode
                sendError("Status Code Error: \(String(describing: code!))")
                return
            }
            guard let data = data else {
                sendError("No Data from Authentication Request")
                return
            }
            let range = Range(5..<data.count)
            let newData = data.subdata(in: range)
            do {
                let authResponse = try JSONDecoder().decode(PostSession.self, from: newData)
                if authResponse.account.registered {
                    DispatchQueue.main.async {
                        OnTheMapClass.sharedInstance.postSession = authResponse
                        self.checkForLocationOnUdacityAPI()
                        self.getUserPublicData()
                    }
                    completionHandlerForAuth(true, nil)
                }
            } catch {
                sendError("Unable to Decode JSON from Request: \(error)")
            }
        }
        task.resume()
    }
    
    func downloadStudentInformation(completionHandlerForInfo: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        var request = buildUrlRequestForParse("GET", Constants.studentLocationDefault)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForInfo(false, NSError(domain: "Download Student Information", code: 1, userInfo: userInfo))
            }
            if error != nil { // Handle error...
                sendError("Error prevented download of Student Information!")
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Could not connect to server for Student Information!")
                return
            }
            guard let data = data else {
                sendError("No Data from Student Information Request!")
                return
            }
            do {
                let studentInfoResponse = try JSONDecoder().decode(StudentLocations.self, from: data)
                var tempArray = [StudentInformation]()
                for record: StudentInformation in studentInfoResponse.results {
                    if OnTheMapClient.instance.isCompleteStudentInformation(record: record) {
                        tempArray.append(record)
                    }
                }
                tempArray = tempArray.sorted()
                DispatchQueue.main.async {
                    OnTheMapClass.sharedInstance.studentLocations = tempArray
                    NotificationCenter.default.post(name: Notification.Name("StudentLocationsDownloaded"), object: nil)
                }
                completionHandlerForInfo(true, nil)
            } catch {
                sendError("Unable to Decode JSON from Info Request!")
            }
        }
        task.resume()
    }
    
    func isCompleteStudentInformation(record: StudentInformation) -> Bool {
        if record.firstName == nil || record.lastName == nil || record.latitude == nil || record.longitude == nil || record.mediaURL == nil {
            return false // Important information is missing
        }
        let pattern = "((https|http)://)((\\w|-)+)(([.]|[/])((\\w|-)+))+"
        let predicate = NSPredicate(format:"SELF MATCHES %@", argumentArray:[pattern])
        return predicate.evaluate(with: record.mediaURL)
    }
    
    func deleteSessionWithUdacityApi() {
        var request = URLRequest(url: URL(string: Constants.sessionUrl)!)
        request.httpMethod = "DELETE"
        var xsrfCookie: HTTPCookie? = nil
        let sharedCookieStorage = HTTPCookieStorage.shared
        for cookie in sharedCookieStorage.cookies! {
            if cookie.name == "XSRF-TOKEN" { xsrfCookie = cookie }
        }
        if let xsrfCookie = xsrfCookie {
            request.setValue(xsrfCookie.value, forHTTPHeaderField: "X-XSRF-TOKEN")
        }
        let task = URLSession.shared.dataTask(with: request)
        task.resume()
    }
    
    func getLocalSearchLocationFromString(_ stringName: String, completionHandler: @escaping (_ mapItems: MKLocalSearchResponse?, _ error: Error?) -> Void) {
        let request  = MKLocalSearchRequest()
        request.naturalLanguageQuery = stringName
        let localSearch = MKLocalSearch(request: request)
        localSearch.start() { mapItems, error in
            completionHandler(mapItems, error)
        }
    }
    
    func sendInformationToUdacityApi(_ locationInfo: LocationInformation, handler: @escaping (_ response: Bool, _ error: Error?) -> Void) {
        func sendError(_ error: String) {
            let userInfo = [NSLocalizedDescriptionKey : error]
            handler(false, NSError(domain: "Send Information To Udacity Api", code: 1, userInfo: userInfo))
        }
        var json: Data?
        do {
            json = try JSONEncoder().encode(locationInfo)
        } catch {
            sendError("Unable to create query to send information to Udacity")
            return
        }
        
        if OnTheMapClass.sharedInstance.hasExistingLocationStored {
            let object = OnTheMapClass.sharedInstance.studentInformationObject!
            let urlString = Constants.studentLocation + "/" + object.objectId!
            var request = buildUrlRequestForParse("PUT", urlString)
            
            
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = json
            let session = URLSession.shared
            let task = session.dataTask(with: request) { data, response, error in
                if error != nil { // Handle error…
                    sendError("Error from Student Information Update request: \(error!.localizedDescription)")
                    return
                }
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                    sendError("Could not connect to Udacity API to update Student Information!")
                    return
                }
                guard let data = data else {
                    sendError("No Data returned from Student Information PUT Request!")
                    return
                }
                do {
                    let putResponse = try JSONDecoder().decode(CompletedPutOfUserLocationResponse.self, from: data)
                    if putResponse.updatedAt != nil {
                        self.checkForLocationOnUdacityAPI()
                        handler(true, nil)
                        return
                    } else {
                        sendError("Student Information Update not Completed!")
                        return
                    }
                } catch {
                    sendError("JSON Parse of Student Info update request failed!")
                    return
                }
            }
            task.resume()
        } else {
            var request = buildUrlRequestForParse("POST", Constants.studentLocation)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = json
            let session = URLSession.shared
            let task = session.dataTask(with: request) { data, response, error in
                if error != nil { // Handle error…
                    sendError("Error from Student Information Creation request: \(error!.localizedDescription)")
                    return
                }
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                    sendError("Could not connect to Udacity API to create Student Information!")
                    return
                }
                guard let data = data else {
                    sendError("No Data returned from Student Information POST Request!")
                    return
                }
                do {
                    let postResponse = try JSONDecoder().decode(CompletedPostOfUserLocationResponse.self, from: data)
                    if postResponse.createdAt != nil {
                        self.checkForLocationOnUdacityAPI()
                        handler(true, nil)
                    } else {
                        sendError("Student Information Creation not Completed!")
                        return
                    }
                } catch {
                    sendError("JSON Parse of Student Info creation request failed!")
                    return
                }
            }
            task.resume()
        }
    }
    
    func checkForLocationOnUdacityAPI() {
        guard let key = OnTheMapClass.sharedInstance.postSession?.account.key else {
            return
        }
        let jsonEncoder = JSONEncoder()
        var uniqueKey: String = ""
        do {
            let json = try jsonEncoder.encode(UniqueKeyJson(uniqueKey: key))
            uniqueKey = String(data: json, encoding: .utf8)!
            uniqueKey = uniqueKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        } catch {
            return
        }
        let urlString = Constants.loggedInStudentLocation + uniqueKey
        let request = buildUrlRequestForParse("GET", urlString)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil { // Handle error
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                return
            }
            guard let data = data else {
                return
            }
            do {
                // results
                let studentInfoResponse = try JSONDecoder().decode(StudentLocations.self, from: data)
                if studentInfoResponse.results.count > 0 {
                    let studentInfo = studentInfoResponse.results[0]
                    if studentInfo.objectId != nil {
                        OnTheMapClass.sharedInstance.studentInformationObject = studentInfo
                        OnTheMapClass.sharedInstance.hasExistingLocationStored = true
                    }
                } else {
                    OnTheMapClass.sharedInstance.hasExistingLocationStored = false
                }
            } catch {
                OnTheMapClass.sharedInstance.hasExistingLocationStored = false
            }
        }
        task.resume()
    }
    
    func getUserPublicData() {
        guard let key = OnTheMapClass.sharedInstance.postSession?.account.key else {
            return
        }
        let request = URLRequest(url: URL(string: Constants.userUrl + "/" + key)!)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil { // Handle error...
                return
            }
            guard let data = data else {
                return
            }
            let range = Range(5..<data.count)
            let newData = data.subdata(in: range) /* subset response data! */
            do {
                let userResponse = try JSONDecoder().decode(PublicUserJson.self, from: newData)
                OnTheMapClass.sharedInstance.studentPublicInformation = userResponse.user
            } catch {
                return
            }
        }
        task.resume()
    }
    
    func buildUrlRequestForParse(_ method: String, _ url: String) -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = method
        request.addValue("QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr", forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue("QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY", forHTTPHeaderField: "X-Parse-REST-API-Key")
        return request
    }
}
