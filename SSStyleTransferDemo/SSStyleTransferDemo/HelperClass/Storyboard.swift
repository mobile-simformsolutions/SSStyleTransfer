//
//  Storyboard.swift
//  SSStyleTransferDemo
//
//  Created by Sanya Pillai on 10/07/21.
//

import Foundation
import UIKit

enum Storyboard: String {
    case Main = "Main"
}

protocol Storyboarded {
    static func instantiate(from storyBoard: Storyboard) -> Self
}

extension Storyboarded where Self: UIViewController {
    
    static func instantiate(from storyBoard: Storyboard) -> Self {
        let fullname = NSStringFromClass(self)
        let className = fullname.components(separatedBy: ".")[1]
        let storyBoardName = UIStoryboard(name: storyBoard.rawValue, bundle: nil)
        return storyBoardName.instantiateViewController(withIdentifier: className) as! Self
    }
}
