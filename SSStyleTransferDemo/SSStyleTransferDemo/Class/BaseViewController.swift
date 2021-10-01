//
//  BaseViewController.swift
//  SSStyleTransferDemo
//
//  Created by Sanya Pillai on 20/08/21.
//

import UIKit

class BaseViewController: UIViewController,Storyboarded {
    // MARK: - Variable Declaration

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    
    // MARK: - Function declaration
    
    func showFilterOptions(callBack: @escaping (SSStyle?) -> Void) {
       
        let waterBlueStyle = UIAlertAction(title: "WaterBlue", style: .default) { (_) in
            callBack(.waterBlue)
        }
        
        let fieryFireStyle = UIAlertAction(title: "FieryFire", style: .default) { (_) in
            callBack(.fieryFire)
        }
        
        let frozenBlackStyle = UIAlertAction(title: "FrozenBlack", style: .default) { (_) in
            callBack(.frozenBlack)
        }
        
        let frozenBlueStyle = UIAlertAction(title: "frozenBlue", style: .default) { (_) in
            callBack(.frozenBlue)
        }
        
        let wavyStyle = UIAlertAction(title: "Wavy", style: .default) { (_) in
            callBack(.wavy)
        }
        
        let starryNightsStyle = UIAlertAction(title: "StarryNights", style: .default) { (_) in
            callBack(.starryNights)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { UIAlertAction in
            callBack(nil)
        }
        
        let actionArray = [waterBlueStyle, fieryFireStyle, frozenBlackStyle, frozenBlueStyle, wavyStyle, starryNightsStyle, cancelAction]
        let alertController = UIAlertController.showAlert(title: "", message: nil, actions: actionArray, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRect(origin: self.view.bounds.origin, size: self.view.bounds.size)
        self.present(alertController, animated: true, completion: nil)
    }
    
}

// TODO: - To enable native swipe(back) gesture
extension BaseViewController: UIGestureRecognizerDelegate {

}
