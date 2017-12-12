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
    
    var appDelegate: AppDelegate! = UIApplication.shared.delegate as? AppDelegate
    
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
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        appDelegate.postSession = authResponse
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
                sendError("Error returned from Information Session")
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                let code = (response as? HTTPURLResponse)?.statusCode
                sendError("Status Code Error: \(String(describing: code!))")
                return
            }
            guard let data = data else {
                sendError("No Data from Student Information Request")
                return
            }
            do {
                let studentInfoResponse = try JSONDecoder().decode(StudentLocations.self, from: data)
                var tempArray = [StudentInformation]()
                for record: StudentInformation in studentInfoResponse.results {
                    if OnTheMapClient.sharedInstance().isCompleteStudentInformation(record: record) {
                        tempArray.append(record)
                    }
                }
                DispatchQueue.main.async {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.studentLocations = tempArray
                    NotificationCenter.default.post(name: Notification.Name("StudentLocationsDownloaded"), object: nil)
                }
                completionHandlerForInfo(true, nil)
            } catch {
                sendError("Unable to Decode JSON from Info Request: \(error)")
            }
        }
        task.resume()
    }
    
    func isCompleteStudentInformation(record: StudentInformation) -> Bool {
        if record.firstName == nil || record.lastName == nil || record.latitude == nil || record.longitude == nil || record.mediaURL == nil {
            return false // Important information is missing
        }
        if !record.mediaURL!.isValidURL() {
            return false // URL cannot be opened
        }
        return true // All info in record
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
    
    class func sharedInstance() ->OnTheMapClient {
        struct Singleton {
            static let instance = OnTheMapClient()
        }
        return Singleton.instance
    }
    
    func getLocalSearchLocationFromString(_ stringName: String, completionHandler: @escaping (_ mapItems: MKLocalSearchResponse?, _ error: Error?) -> Void) {
        let request  = MKLocalSearchRequest()
        request.naturalLanguageQuery = stringName
        let localSearch = MKLocalSearch(request: request)
        localSearch.start() { mapItems, error in
            completionHandler(mapItems, error)
        }
    }
    
    func sendInformationToUdacityApi(_ mapItem: MKMapItem, _ link: String, handler: @escaping (_ response: Bool, _ error: Error?) -> Void) {
        func sendError(_ result: Bool, _ error: String) {
            let userInfo = [NSLocalizedDescriptionKey : error]
            handler(result, NSError(domain: "Send Information To Udacity Api", code: 1, userInfo: userInfo))
        }
        guard let key = appDelegate.postSession?.account.key else {
            sendError(false, "Missing Unique Key")
            return
        }
        guard let student = appDelegate.studentPublicInformation else {
            sendError(false, "Missing Public Information Object")
            return
        }
        if appDelegate.hasExistingLocationStored {
            let object = appDelegate.studentInformationObject!
            let urlString = Constants.studentLocation + "/" + object.objectId!
            var request = buildUrlRequestForParse("PUT", urlString)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = "{\"uniqueKey\": \"\(key)\", \"firstName\": \"\(student.first_name!)\", \"lastName\": \"\(student.last_name!)\",\"mapString\": \"\(String(describing: mapItem.name))\", \"mediaURL\": \"\(link)\",\"latitude\": \(mapItem.placemark.coordinate.latitude), \"longitude\": \(mapItem.placemark.coordinate.longitude)}".data(using: .utf8)
            let session = URLSession.shared
//            let task = session.dataTask(with: request) { data, response, error in
//                if error != nil { // Handle error…
//                    sendError(false, "Error on PUT method")
//                    return
//                }
//                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
//                    let code = (response as? HTTPURLResponse)?.statusCode
//                    sendError(false, "Status Code Error: \(String(describing: code!))")
//                    return
//                }
//                guard let data = data else {
//                    sendError(false, "No Data from Student Information PUT Request")
//                    return
//                }
//                do {
//                    let putResponse = try JSONDecoder().decode(CompletedPutOfUserLocationResponse.self, from: data)
//                    if putResponse.updatedAt != nil {
//                        sendError(true, "")
//                        return
//                    } else {
//                        sendError(false, "No Updated At date provided")
//                        return
//                    }
//                } catch {
//                    sendError(false, "JSON Parse of POST request failed")
//                    return
//                }
//            }
//            task.resume()
        } else {
            var request = buildUrlRequestForParse("POST", Constants.studentLocation)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = "{\"uniqueKey\": \"\(key)\", \"firstName\": \"\(student.first_name!)\", \"lastName\": \"\(student.last_name!)\",\"mapString\": \"\(mapItem.name!)\", \"mediaURL\": \"\(link)\",\"latitude\": \(mapItem.placemark.coordinate.latitude), \"longitude\": \(mapItem.placemark.coordinate.longitude)}".data(using: .utf8)
            let session = URLSession.shared
//            let task = session.dataTask(with: request) { data, response, error in
//                if error != nil { // Handle error…
//                    sendError(false, "Error on POST method")
//                    return
//                }
//                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
//                    let code = (response as? HTTPURLResponse)?.statusCode
//                    sendError(false, "Status Code Error: \(String(describing: code!))")
//                    return
//                }
//                guard let data = data else {
//                    sendError(false, "No Data from Student Information POST Request")
//                    return
//                }
//                do {
//                    let postResponse = try JSONDecoder().decode(CompletedPostOfUserLocationResponse.self, from: data)
//                    if postResponse.createdAt != nil {
//                        sendError(true, "")
//                    } else {
//                        sendError(false, "No Created At date provided")
//                    }
//                } catch {
//                    sendError(false, "JSON Parse of POST request failed")
//                    return
//                }
//            }
//            task.resume()
        }
    }
    
    func checkForLocationOnUdacityAPI() {
        guard let key = appDelegate.postSession?.account.key else {
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
            print(String(data: data, encoding: .utf8)!)
            do {
                // results
                let studentInfoResponse = try JSONDecoder().decode(StudentLocations.self, from: data)
                if studentInfoResponse.results.count > 0 {
                    let studentInfo = studentInfoResponse.results[0]
                    if studentInfo.objectId != nil {
                        self.appDelegate.studentInformationObject = studentInfo
                        self.appDelegate.hasExistingLocationStored = true
                    }
                }
            } catch {
                print("student check JSON parsing failed")
            }
        }
        task.resume()
    }
    
    func getUserPublicData() {
        guard let key = appDelegate.postSession?.account.key else {
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
                self.appDelegate.studentPublicInformation = userResponse.user
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

extension String {
    
    func isValidURL() -> Bool {
        guard let url = URLComponents.init(string: self) else {
            return false
        }
        guard url.host != nil, url.url != nil else {
            return false
        }
        if (url.host?.isEmpty)! {
            return false
        }
        return true
    }
}
