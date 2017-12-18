//
//  AddLocationViewController.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 14/11/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class AddLocationViewController: UIViewController {
    
    @IBOutlet var linkField: UITextField!
    @IBOutlet var locationField: UITextField!
    @IBOutlet var findLocationButton: UIButton!
    var mapItem: MKMapItem?
    var shouldSegue: Bool = false
    
    @IBAction func cancelAddAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func findLocationAction(_ sender: UIButton) {
        guard let link = linkField.text, !link.isEmpty else {
            displayAlert(title: "Missing Link", msg: "No Link has been provided.")
            return
        }
        guard let location = locationField.text, !location.isEmpty else {
            displayAlert(title: "Missing Location", msg: "Enter a Location as string!")
            return
        }
        shouldSegue = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        OnTheMapClient.sharedInstance().getLocalSearchLocationFromString(location) { (response, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                if error != nil {
                    self.displayAlert(title: "An Error Occurred", msg: "The Location lookup failed: \(error?.localizedDescription ?? "No Description")")
                    return
                }
                guard let response = response else {
                    self.displayAlert(title: "Missing Locations", msg: "We were unable to find Location for \(location), please try again.")
                    return
                }
                if response.mapItems.count > 0 {
                    self.mapItem = response.mapItems[0]
                    self.shouldSegue = true
                    self.performSegue(withIdentifier: "ShowAddLocationConfirm", sender: nil)
                } else {
                    self.displayAlert(title: "No Locations", msg: "We were unable to find Location for \(location), please try again.")
                    return
                }
            }
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "ShowAddLocationConfirm", shouldSegue {
            return true
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowAddLocationConfirm" {
            if let controller = segue.destination as? LocationConfirmationViewController {
                controller.mapItem = self.mapItem!
                controller.link = self.linkField.text
            }
        }
    }
    
    
}
