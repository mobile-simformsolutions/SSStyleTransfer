//
//  SSVideoViewController.swift
//  SSStyleTransferDemo
//
//  Created by Sanya Pillai on 07/09/21.
//

import UIKit

class SSVideoViewController: BaseViewController {
    
    // MARK: Variable declaration
    var pickerManager = VideoPickerManager()
    var selectedURL: URL?
    internal var coordinator: SSVideoViewController?
    var styleTransfer: SSStyleTransferFilter?
    var customProgress = SSProgressView()
    
    // MARK: Outlet declaration
    @IBOutlet weak var videoView: SSStyleTransferVideoView!
    @IBOutlet weak var btnPlay: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadDefaultVideo()
        styleTransfer = SSStyleTransferFilter()
        styleTransfer!.modelComputeUnits = .cpuOnly
        styleTransfer!.styleTransferDelegte = self
        styleTransfer!.currentStyle = .waterBlue
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        selectedURL = nil
        styleTransfer = nil
        videoView.player = nil
        videoView = nil
    }
    
    func loadDefaultVideo() {
        guard let path = Bundle.main.path(forResource: "video", ofType:"mp4") else {
            debugPrint("video.mp4 not found")
            return
        }
        selectedURL = URL(fileURLWithPath: path)
        videoView.url = selectedURL
        btnPlay.isHidden = false
    }
    
    func showErrorAlert() {
        let okAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
        let errorAlert = UIAlertController.showAlert(title: "", message: "Please select video", actions: [okAction], preferredStyle: .alert)
        present(errorAlert, animated: true, completion: nil)
    }
    
    func addProgress() {
        customProgress.frame = view.frame
        UIApplication.shared.windows.first {$0.isKeyWindow}?.addSubview(customProgress)
        customProgress.cancelButtonClosure = { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.styleTransfer!.cancelFilter()
            weakSelf.hideProgress()
        }
        customProgress.showSpinner()
    }
    
    func hideProgress() {
        customProgress.hideSpinner()
        customProgress.removeFromSuperview()
    }
}


// MARK: Action Methods

extension SSVideoViewController {
    
    @IBAction func onSelectFilter(_ sender: UIButton) {
        if selectedURL != nil  {
            self.showFilterOptions {[weak self]  (filteredSelected) in
                if let filter = filteredSelected {
                    self?.styleTransfer!.currentStyle = filter
                }
            }
        } else {
            showErrorAlert()
        }
    }
    
    @IBAction func onSelectVideo(_ sender: UIButton) {
        pickerManager.pickVideo(self, sourceView: sender, delegate: self)
    }
    
    @IBAction func onPlay(_ sender: UIButton) {
        if selectedURL != nil  {
            guard let player = videoView.player else {return}
            player.isMuted = false
            if player.isPlaying {
                btnPlay.setImage(UIImage(named: "play"), for: .normal)
                player.pause()
            } else {
                btnPlay.setImage(nil, for: .normal)
                player.play()
            }
            
        } else {
            showErrorAlert()
        }
    }
    
    @IBAction func onApplyFilter(_ sender: UIButton) {
        if let url = selectedURL {
            if let player = videoView.player, player.isPlaying {
                btnPlay.setImage(UIImage(named: "play"), for: .normal)
                player.pause()
            }
            addProgress()
            styleTransfer!.applyAndSaveFilteredVideo(url: url)
        } else {
            showErrorAlert()
        }
    }
    
    @IBAction func onSaveVideo(_ sender: UIButton) {
        styleTransfer!.saveVideoToGallery()
    }
}


extension SSVideoViewController: VideoPickerDelegate {
    
    func didSelect(url: URL?) {
        guard let movieUrl = url else {
            return
        }
        selectedURL = movieUrl
        videoView.url = selectedURL
        btnPlay.isHidden = false
    }
}

extension SSVideoViewController: SStyleTransferFilterDelegate {
    
    func styleTransferFilterSave(didFinishSavingWithSuccess message:String, withError error: Error?) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func styleTransferFilter(didMakeProgress progress: Float) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.customProgress.setProgressLabel(withProgress: "Progress: \(ceil(progress))")
        }
    }
    
    func styleTransferFilter(didFinishWithURL url: URL) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.hideProgress()
            weakSelf.videoView.url = url
        })
    }
    
    func styleTransferFilter(didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.hideProgress()
        }
    }
    
}
