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
    
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    
    @IBAction func loginUser(_ sender: UIButton) {
        var request = URLRequest(url: URL(string: "https://www.udacity.com/api/session")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{\"udacity\": {\"username\": \"\(username.text!)\", \"password\": \"\(password.text!)\"}}".data(using: .utf8)
        let session = URLSession.shared
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            if error != nil { // Handle error…
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("error")
                return
            }
            guard let data = data else {
                print("error")
                return
            }
            let range = Range(5..<data.count)
            let newData = data.subdata(in: range) /* subset response data! */
            print(String(data: newData, encoding: .utf8)!)
            let parsedResults: [String:AnyObject]!
            do {
                parsedResults = try JSONSerialization.jsonObject(with: newData, options: .allowFragments) as! [String:AnyObject]
            } catch {
                print("error")
                return
            }
            guard let account = parsedResults["account"] as? [String:AnyObject] else {
                print("error")
                return
            }
            guard let registered = account["registered"] as? Bool else {
                print("error")
                return
            }
            if registered {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "LoggedInSegue", sender: self)
                }
            }
        }
        task.resume()
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
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardNotifications()
    }
    
    func keyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    func unsubscribeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
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
            var distance = activeField.y - viewFrame.height // Set distance Active Text Field is below Keyboard
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
        unsubscribeKeyboardNotifications()
    }
}

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
