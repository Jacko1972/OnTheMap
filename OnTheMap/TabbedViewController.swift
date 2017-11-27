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
    @IBAction func addStudentLocation(_ sender: Any) {
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        startStudentInfoUpdate()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startStudentInfoUpdate() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        OnTheMapClient.sharedInstance().downloadStudentInformation() { (success, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                if !success {
                    print("error: \(String(describing: error?.domain)) \(String(describing: error?.localizedDescription))")
                }
            }
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
