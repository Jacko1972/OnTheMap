//
//  ListTableViewController.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 14/11/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import UIKit

class ListTableViewController: UITableViewController {

    var appDelegate: AppDelegate! = UIApplication.shared.delegate as? AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "On The Map"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(loadAnnotations), name: NSNotification.Name(rawValue: "StudentLocationsDownloaded"), object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "StudentLocationsDownloaded"), object: nil)
    }
    @objc func loadAnnotations() {
        if appDelegate.studentLocations.count > 0 {
            self.tableView.reloadData()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDelegate.studentLocations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StudentListCell", for: indexPath)
        let studentInfo = appDelegate.studentLocations[indexPath.row]
        cell.textLabel?.text = studentInfo.getFullName()
        cell.detailTextLabel?.text = studentInfo.mediaURL
        return cell
    }
 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let studentInfo = appDelegate.studentLocations[indexPath.row]
        UIApplication.shared.open(URL(string: studentInfo.mediaURL!)!, options: [:], completionHandler: nil)
    }
}
