//
//  ViewController.swift
//  SSStyleTransferDemo
//
//  Created by Sanya Pillai on 20/08/21.
//

import UIKit

class ViewController: UIViewController {

    var coordinator: ViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func btnVideoFilter(_ sender: UIButton) {
        let videoController = SSVideoViewController.instantiate(from: .Main)
        self.navigationController?.pushViewController(videoController, animated: true)
    }
    
    
    @IBAction func btnPhotoFilter(_ sender: UIButton) {
        let videoController = SSImageViewController.instantiate(from: .Main)
        self.navigationController?.pushViewController(videoController, animated: true)
    }
}

