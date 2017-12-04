//
//  Extensions.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 28/11/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import UIKit

extension UIViewController {
    func displayAlert(title : String?, msg : String, style: UIAlertControllerStyle = .alert) {
        let alert = UIAlertController.init(title: title, message: msg, preferredStyle: style)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}

public extension String {
    public var isValidEmail: Bool {
        return matches(pattern: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
    }
    public func matches(pattern: String) -> Bool {
        return range(of: pattern, options: String.CompareOptions.regularExpression, range: nil, locale: nil) != nil
    }
}
