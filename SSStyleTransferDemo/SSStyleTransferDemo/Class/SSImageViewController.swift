//
//  SSImageViewController.swift
//  SSStyleTransferDemo
//
//  Created by Sanya Pillai on 07/09/21.
//

import UIKit

class SSImageViewController: BaseViewController {
    
    // MARK: Variable declaration
    var selectedURL: URL?
    internal var coordinator: SSImageViewController?
    let styleTransfer: SSStyleTransferFilter = SSStyleTransferFilter()
    var pickerManager = ImagePickerManager()
    var selectedImage: UIImage?
    
    // MARK: Outlet declaration
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedImage = UIImage(named: "DefaultImage")
        styleTransfer.modelComputeUnits = .cpuOnly
        styleTransfer.styleTransferDelegte = self
        styleTransfer.currentStyle = .waterBlue
    }
}


// MARK: Action Methods

extension SSImageViewController {
    
    @IBAction func onSelectFilter(_ sender: UIButton) {
        self.showFilterOptions {[weak self]  (filteredSelected) in
            if let filter = filteredSelected {
                self?.styleTransfer.currentStyle = filter
            }
        }
    }
    
    @IBAction func onApplyFilter(_ sender: UIButton) {
        if let originalImage = selectedImage {
            styleTransfer.applyFilterTo(image: originalImage) { [weak self] (filteredImage, error) in
                if (filteredImage != nil) {
                    self?.imageView.image = filteredImage
                }
            }
        }
    }
    
    @IBAction func onSelectImage(_ sender: UIButton) {
        pickerManager.pickImage(self, sourceView: sender, showRemovePhoto: false) {[weak self] (image) in
            guard let uSelf = self else {return}
            uSelf.selectedImage = image
            uSelf.imageView.image = image;
        } _: { (isShow) in }
    }
    
    @IBAction func onSavePhoto(_ sender: UIButton) {
        if let originalImage = imageView.image {
            styleTransfer.savePhotoToGallery(photo: originalImage)
        }
    }
}

extension SSImageViewController: SStyleTransferFilterDelegate {
    
    func styleTransferFilterSave(didFinishSavingWithSuccess message:String, withError error: Error?) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
}
