//
//  ImagePickerManager.swift
//  Layer
//
//  Created by Abhi Makadiya on 02/11/20.
//  Copyright © 2020 Simform Solutions Pvt. Ltd.. All rights reserved.
//

import UIKit
import AVKit
import Photos

class ImagePickerManager: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var picker = UIImagePickerController()
    var alert: UIAlertController?
    weak var viewController: UIViewController?
    var pickImageCallback: ((UIImage?) -> Void)?
    
    override init() {
        super.init()
    }
    
    /// PickImage: pick image from device
    ///
    /// - Parameters:
    ///   - viewController: current controller
    ///   - sourceView: for iPad use
    ///   - callback: get image on call back
    func pickImage(_ viewController: UIViewController, sourceView: UIView, showRemovePhoto: Bool, _ callback: @escaping ((UIImage?) -> Void), _ showImage: @escaping ((Bool) -> Void)) {
        
        pickImageCallback = callback
        self.viewController = viewController
        
        let showImageAction = UIAlertAction(title: "showPhoto", style: .default) { UIAlertAction in
            showImage(showRemovePhoto)
        }
        
        let removeImageAction = UIAlertAction(title: "removePhoto", style: .default) { UIAlertAction in
            self.removeImage()
        }
        
        let cameraAction = UIAlertAction(title: "camera", style: .default) { UIAlertAction in
            self.checkForCameraPermisstion(completion: { (success) in
                if success {
                    self.openCamera()
                } else {
                    DispatchQueue.main.async { [weak self] in
                        guard let uSelf = self else {
                            return
                        }
                        uSelf.showAlert(title: "unableToAccessTheVideocameracamera" , message: "toEnableAccessTheCamera")
                    }
                }
            })
        }
        let gallaryAction = UIAlertAction(title: "photos", style: .default) { UIAlertAction in
            self.checkForGallryPermisstion(completion: { (success) in
                if success {
                    self.openGallery()
                } else {
                    self.showAlert(title: "unableToAccessThephotos" , message: "toEnableAccessThePhotos")
                }
            })
        }
        let cancelAction = UIAlertAction(title: "cancel", style: .cancel) { UIAlertAction in
            showImage(false)
        }
        
        // Add the actions
        picker.delegate = self
        var actionArray  = [cameraAction, gallaryAction, cancelAction]
        if showRemovePhoto {
            actionArray.insert(removeImageAction, at: 0)
            actionArray.insert(showImageAction, at: 0)
        }
        alert = UIAlertController.showAlert(title: "chooseImage", message: nil, actions: actionArray, preferredStyle: .actionSheet)
        if let alert = alert {
            alert.popoverPresentationController?.sourceView = sourceView
            alert.popoverPresentationController?.sourceRect = CGRect(x: sourceView.bounds.origin.x, y: sourceView.bounds.origin.y, width: sourceView.bounds.width, height: sourceView.bounds.height)
            viewController.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    /// Check For Camera Permisstion
    ///
    /// - Parameter completion: Is permisstion granted or not
    func checkForCameraPermisstion(completion: @escaping (Bool) -> Void) {
        //Camera
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            // ask for permissions
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    completion(true)
                } else {
                    completion(false)
                }
            })
        case .restricted, .denied:
            completion(false)
        case .authorized:
            completion(true)
        // Default case added by swift 5 this will never execute
        @unknown default:
            fatalError("checkForCameraPermisstion")
        }
    }
    
    /// Check For Gallry Permisstion
    ///
    /// - Parameter completion: Is permisstion granted or not
    func checkForGallryPermisstion(completion: @escaping (Bool) -> Void) {
        
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            completion(true)
        case .denied, .restricted :
            completion(false)
        case .notDetermined:
            // ask for permissions
            PHPhotoLibrary.requestAuthorization { newStatus in
                switch newStatus {
                case .authorized:
                    completion(true)
                case .denied, .restricted :
                    completion(false)
                case .notDetermined:
                    completion(false)
                default:
                    completion(false)
                }
            }
        default:
            completion(false)
        }
        
    }
    
    /// Show Alert
    ///
    /// - Parameters:
    ///   - title: Get alert title
    ///   - message: Get alert message
    func showAlert(title: String, message: String) {
        self.alert?.dismiss(animated: true, completion: nil)
        
        let okAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
        
        let settingsAction = UIAlertAction(title: "settings", style: .default, handler: { _ in
            // Take the user to Settings app to possibly change permission.
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    // Finished opening URL
                })
            }
        })
        
        let settingsAlert = UIAlertController.showAlert(title: title, message: message, actions: [okAction, settingsAction], preferredStyle: .alert)
        self.viewController?.present(settingsAlert, animated: true, completion: nil)
    }
    
    /// Open Camera
    func openCamera() {
        DispatchQueue.delay(bySeconds: 0.0, closure: { [weak self] in
            guard let uSelf = self else {return}
            uSelf.alert?.dismiss(animated: true, completion: nil)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                uSelf.picker.sourceType = .camera
                uSelf.viewController?.present(uSelf.picker, animated: true, completion: nil)
            } else {
                let cancelAction = UIAlertAction(title: "cancel", style: .cancel) { UIAlertAction in
                }
                let alertWarning = UIAlertController.showAlert(title: "warning", message: "youDoNotHaveCamera", actions: [cancelAction], preferredStyle: .alert)
                if let view = uSelf.viewController?.view {
                    alertWarning.popoverPresentationController?.sourceView = view
                    uSelf.viewController?.present(alertWarning, animated: true, completion: nil)
                }
            }
        })
        
        
    }
    
    /// Open Gallery
    func openGallery() {
        DispatchQueue.delay(bySeconds: 0.0, closure: { [weak self] in
            guard let uSelf = self else {return}
            uSelf.alert?.dismiss(animated: true, completion: nil)
            uSelf.picker.sourceType = .photoLibrary
            uSelf.viewController?.present(uSelf.picker, animated: true, completion: nil)
        })
    }
    
    /// Remove Image
    func removeImage() {
        pickImageCallback?(nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[.originalImage] as? UIImage else {
            print("Not getting image")
            return
        }
        pickImageCallback?(image)
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, pickedImage: UIImage?) {
        print("@objc func imagePickerController called")
    }
    
}
