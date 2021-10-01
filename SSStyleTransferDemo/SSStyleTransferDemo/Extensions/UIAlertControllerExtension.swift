//
//  UIAlertController+Extension.swift
//  Layer
//
//  Created by Abhi Makadiya on 02/11/20.
//  Copyright © 2020 Simform Solutions Pvt. Ltd.. All rights reserved.
//

import UIKit

extension UIAlertController {

    /// To show alert in viewController
    ///
    /// - Parameters:
    ///   - title: Title of alert like "My Alert"
    ///   - message: what the purpose of alert
    ///   - actions: get input from user
    ///   - preferredStyle: Constants indicating the type of alert to display
    /// - Returns: An object that displays an alert message to the user
    static public func showAlert(title: String?, message: String?, actions: [UIAlertAction], preferredStyle: UIAlertController.Style) -> UIAlertController {
        let controller = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        for action in actions {
            controller.addAction(action)
        }
        return controller
    }

}
