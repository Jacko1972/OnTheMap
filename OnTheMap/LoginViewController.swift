//
//  LoginViewController.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 13/11/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    var keyBoardHeight: CGFloat = 0
    var activeTextField: UITextField!
    
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    
    @IBAction func loginUser(_ sender: UIButton) {
        guard let user = username.text, !user.isEmpty, user.isValidEmail else {
            displayAlert(title: "Missing Username", msg: "Ensure you have entered your Username correctly!")
            return
        }
        guard let pass = password.text, !pass.isEmpty else {
            displayAlert(title: "Missing Password", msg: "Ensure you have entered your Password correctly!")
            return
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        OnTheMapClient.sharedInstance().authenticateWithUdacityApi(user, password: pass) { (success, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                if success {
                    self.performSegue(withIdentifier: "LoggedInSegue", sender: self)
                } else {
                    self.displayAlert(title: "User Login Failed",
                                      msg: "Domain: \(String(describing: error!.domain)). The system returned the following error: \(String(describing: error!.localizedDescription))")
                }
            }
        }
    }
    
    @IBAction func signUp(_ sender: UIButton) {
        if let url = URL(string: "https://www.udacity.com/account/auth#!/signup") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        username.delegate = self
        password.delegate = self
        loginButton.setTitle("LOGIN", for: .normal)
        loginButton.setTitle("No Internet", for: .disabled)
    }
    
    @objc func networkStatusChanged(_ notification: Notification) {
        let status = Reach().connectionStatus()
        switch status {
        case .offline, .unknown:
            updateUiToAllowInternetActions(false)
        default:
            updateUiToAllowInternetActions(true)
        }
    }
    
    func updateUiToAllowInternetActions(_ available: Bool) -> Void {
        loginButton.isEnabled = available
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToNotifications()
        Reach().monitorReachabilityChanges()
    }
    
    func subscribeToNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(networkStatusChanged(_:)), name: NSNotification.Name(rawValue: ReachabilityStatusChangedNotification), object: nil)
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: ReachabilityStatusChangedNotification), object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        keyBoardHeight = getKeyboardHeight(notification)
        moveKeyboard()
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
    
    @objc func keyboardWillHide(_ notification: Notification) {
        keyBoardHeight = 0
        view.frame.origin.y = keyBoardHeight
    }
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromNotifications()
    }
}

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
