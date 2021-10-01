//
//  SSProgressView.swift
//  SSStyleTransferDemo
//
//  Created by Sanya Pillai on 23/08/21.
//

import Foundation
import UIKit

class SSProgressView: UIView {
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet private weak var progressLabel: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    public var cancelButtonClosure: (() -> ())?
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadViewFromNib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadViewFromNib()
    }
    
    func loadViewFromNib() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        view.frame = bounds
        view.autoresizingMask = [
            UIView.AutoresizingMask.flexibleWidth,
            UIView.AutoresizingMask.flexibleHeight
        ]
        addSubview(view)
    }
    
    
    func showSpinner() {
        DispatchQueue.delay(bySeconds: 0.0) { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.activityIndicator.startAnimating()
        }
    }
    
    func hideSpinner() {
        DispatchQueue.delay(bySeconds: 0.0) { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.activityIndicator.stopAnimating()
        }
    }
    
    func setProgressLabel(withProgress title: String) {
        progressLabel.text = title
    }
    
    @IBAction func onCancelButtonTap(_ sender: UIButton) {
        if let cancelClosure = cancelButtonClosure {
            cancelClosure()
        }
    }
}




