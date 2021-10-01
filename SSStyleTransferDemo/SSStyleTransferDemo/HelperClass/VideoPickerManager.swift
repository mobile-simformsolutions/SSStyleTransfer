//
//  VideoPickerManager.swift
//  SSStyleTransferDemo
//
//  Created by Sanya Pillai on 31/03/21.
//

import UIKit
import AVKit
import Photos

public protocol VideoPickerDelegate: class {
    func didSelect(url: URL?)
}

class VideoPickerManager: NSObject {
    
    private var pickerViewController = UIImagePickerController()
    private weak var viewController: UIViewController?
    private weak var delegate: VideoPickerDelegate?
    private var alertController: UIAlertController?
    
    override init() {
        super.init()
    }
    
    func pickVideo(_ viewController: UIViewController, sourceView: UIView, delegate: VideoPickerDelegate) {
        self.viewController = viewController
        self.delegate = delegate
    
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] UIAlertAction in
            guard let weakSelf = self else {
                return
            }
            weakSelf.checkForCameraPermisstion(completion: { (success) in
                weakSelf.showAlert(title: "unableToAccessTheCamera", message: "Camera filter feature not yet available")
            })
        }
        
        let galleryAction = UIAlertAction(title: "Video", style: .default) { [weak self] UIAlertAction in
            guard let weakSelf = self else {
                return
            }
            weakSelf.checkForGalleryPermisstion(completion: { (success) in
                if success {
                    weakSelf.openGallery()
                } else {
                    weakSelf.showAlert(title: "unableToAccessTheVideo", message: "toEnableAccessTheVideo")
                }
            })
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { UIAlertAction in
        }
        
        pickerViewController.delegate = self
        pickerViewController.mediaTypes = ["public.movie"]
        pickerViewController.allowsEditing = true
        
        let actionArray = [ galleryAction, cancelAction, cameraAction]         
        alertController = UIAlertController.showAlert(title: "", message: nil, actions: actionArray, preferredStyle: .actionSheet)
        
        if let alertControl = alertController {
            alertControl.popoverPresentationController?.sourceView = sourceView
            alertControl.popoverPresentationController?.sourceRect = CGRect(x: sourceView.bounds.origin.x, y: sourceView.bounds.origin.y, width: sourceView.bounds.width, height: sourceView.bounds.height)
            viewController.present(alertControl, animated: true, completion: nil)
        }
    }
    
    func openGallery() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.alertController?.dismiss(animated: true, completion: nil)
            weakSelf.pickerViewController.sourceType = .photoLibrary
            weakSelf.viewController?.present(weakSelf.pickerViewController, animated: true, completion: nil)
        }
    }
    
    func openCamera() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.alertController?.dismiss(animated: true, completion: nil)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                weakSelf.pickerViewController.sourceType = .camera
                weakSelf.viewController?.present(weakSelf.pickerViewController, animated: true, completion: nil)
            } else {
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { UIAlertAction in
                }
                let alert = UIAlertController.showAlert(title: "Warning", message: "You don't have camera access", actions: [cancelAction], preferredStyle: .alert)
                if let view = weakSelf.viewController?.view {
                    alert.popoverPresentationController?.sourceView = view
                    weakSelf.viewController?.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
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
    
    func checkForGalleryPermisstion(completion: @escaping (Bool) -> Void) {
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
    
    func showAlert(title: String, message: String) {
        self.alertController?.dismiss(animated: true, completion: nil)
        
        let okAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
        
        let settingsAction = UIAlertAction(title: "settings", style: .default, handler: { _ in
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
}

extension VideoPickerManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        pickerViewController.dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        pickerViewController.dismiss(animated: true, completion: nil)
        
        guard let url = info[.mediaURL] as? URL else {
            print("Video not found")
            return
        }
        delegate?.didSelect(url: url)
    }
}
