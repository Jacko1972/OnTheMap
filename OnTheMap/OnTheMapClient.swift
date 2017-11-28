//
//  OnTheMapClient.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 16/11/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//
import UIKit
import Foundation

class OnTheMapClient: NSObject {
    
    func authenticateWithUdacityApi(_ username: String, password: String, completionHandlerForAuth: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        var request = URLRequest(url: URL(string: Constants.sessionUrl)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{\"udacity\": {\"username\": \"\(username)\", \"password\": \"\(password)\"}}".data(using: .utf8)
        let session = URLSession.shared
        
        let task = session.dataTask(with: request) { data, response, error in
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForAuth(false, NSError(domain: "authenticateWithUdacityApi", code: 1, userInfo: userInfo))
            }
            if error != nil {
                sendError("An error was reported: \(String(describing: error?.localizedDescription))")
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                let code = (response as? HTTPURLResponse)?.statusCode
                sendError("Status Code Error: \(String(describing: code))")
                return
            }
            guard let data = data else {
                sendError("No Data from Request")
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
        var request = URLRequest(url: URL(string: Constants.studentLocationDefault)!)
        request.addValue("QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr", forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue("QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY", forHTTPHeaderField: "X-Parse-REST-API-Key")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForInfo(false, NSError(domain: "downloadStudentInformation", code: 1, userInfo: userInfo))
            }
            if error != nil { // Handle error...
                sendError("Error returned from Session")
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                let code = (response as? HTTPURLResponse)?.statusCode
                sendError("Status Code Error: \(String(describing: code))")
                return
            }
            guard let data = data else {
                sendError("No Data from Request")
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
                sendError("Unable to Decode JSON from Request: \(error)")
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
