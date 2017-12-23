//
//  AddLocationViewController.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 14/11/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
////

import UIKit
import CoreLocation
import MapKit

class AddLocationViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var linkField: UITextField!
    @IBOutlet var locationField: UITextField!
    @IBOutlet var findLocationButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    var mapItem: MKMapItem?
    var shouldSegue: Bool = false
    var keyBoardHeight: CGFloat = 0
    var activeTextField: UITextField!
    let reachability = Reachability()!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        linkField.delegate = self
        locationField.delegate = self
        findLocationButton.setTitle("Find Location", for: .normal)
        findLocationButton.setTitle("No Internet", for: .disabled)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToNotifications()
    }
    
    @IBAction func cancelAddAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func networkStatusChanged(_ notification: Notification) {
        let reachability = notification.object as! Reachability
        switch reachability.connection {
        case .none:
            allowInternetActions(false)
        default:
            allowInternetActions(true)
        }
    }
    
    func allowInternetActions(_ available: Bool) -> Void {
        findLocationButton.isEnabled = available
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
        toggleActivityIndicator(true)
        OnTheMapClient.instance.getLocalSearchLocationFromString(location) { (response, error) in
            DispatchQueue.main.async {
                self.toggleActivityIndicator(false)
                if error != nil {
                    self.displayAlert(title: "An Error Occurred", msg: "The Location lookup failed: \(error!.localizedDescription)")
                    return
                }
                guard let response = response else {
                    self.displayAlert(title: "Missing Locations", msg: "We were unable to find \(location), please try again.")
                    return
                }
                if response.mapItems.count > 0 {
                    self.mapItem = response.mapItems[0]
                    self.shouldSegue = true
                    self.performSegue(withIdentifier: "ShowAddLocationConfirm", sender: nil)
                } else {
                    self.displayAlert(title: "No Locations", msg: "We were unable to find \(location), please try again.")
                    return
                }
            }
        }
    }
    
    func toggleActivityIndicator(_ animate: Bool) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = animate
        findLocationButton.isHidden = animate
        animate ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
    }

    func subscribeToNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(networkStatusChanged(_:)), name: .reachabilityChanged, object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            print("could not start reachability notifier")
        }
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        keyBoardHeight = getKeyboardHeight(notification)
        if activeTextField != nil {
            moveKeyboard()
        }
    }
    
    func moveKeyboard() {
        var viewFrame: CGRect = self.view.frame // Window Frame
        var activeField: CGPoint = activeTextField.frame.origin // Active Text Field origin
        activeField.y += activeTextField.frame.size.height // Move point to bottom of Active Text Field
        viewFrame.size.height -= keyBoardHeight // Remove Keyboard portion of Window Frame
        
        if !viewFrame.contains(activeField) { // Is the Active Text Field bottom left point now outside Window Frame
            var distance = activeField.y - viewFrame.height // Get distance Active Text Field is below Keyboard
            distance += activeTextField.frame.size.height // Add height of text field to give a gap, not required to be textfield height
            view.frame.origin.y = -distance // Move Window Frame up so Active Field is just above keyboard
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextField = nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == locationField {
            linkField.becomeFirstResponder()
        }
        return true
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        keyBoardHeight = 0
        view.frame.origin.y = keyBoardHeight
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromNotifications()
    }
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
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
                controller.link = linkField.text
            }
        }
    }
}
