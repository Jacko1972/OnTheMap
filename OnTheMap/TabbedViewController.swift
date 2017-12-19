//
//  TabbedViewController.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 14/11/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import UIKit

class TabbedViewController: UITabBarController {

    @IBAction func refreshLocations(_ sender: Any) {
        startStudentInfoUpdate()
    }

    @IBAction func logout(_ sender: UIBarButtonItem) {
        OnTheMapClient.instance.deleteSessionWithUdacityApi()
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startStudentInfoUpdate()
    }
    
    func startStudentInfoUpdate() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        OnTheMapClient.instance.downloadStudentInformation() { (success, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                if !success {
                    self.displayAlert(title: "Information Download Error",
                                      msg: "Domain: \(String(describing: error!.domain)). The system returned the following error: \(String(describing: error!.localizedDescription))")
                }
            }
        }
    }
}
