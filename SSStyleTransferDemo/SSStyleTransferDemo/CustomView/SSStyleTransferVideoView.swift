//
//  SSStyleTransferVideoView.swift
//  SSStyleTransferDemo
//
//  Created by Sanya Pillai on 01/04/21.
//

import UIKit
import AVFoundation

class SSStyleTransferVideoView: UIView {
    
    let pixelBufferAttributes: [String:AnyObject] = [
        String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
    
    lazy var videoOutput = {
        return AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferAttributes)
    }()
    
    let status = "status"

    //MARK: Player layer properties
    open override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    var player: AVPlayer? {
        get {
            playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    public var url: URL? {
        didSet {
            guard let url = self.url else {
                releasePlayer()
                return
            }
            setUpVideo(url: url)
        }
    }
    
    @available(*, unavailable)
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public init() {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    deinit {
        self.releasePlayer()
    }
    
    func setUpVideo(url: URL) {
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player?.currentItem?.add(videoOutput)
        player?.currentItem?.addObserver(self, forKeyPath: status, options: [.old, .new], context: nil)
      
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidPlayToEndTime(_:)), name: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(itemFailedToPlayToEndTime(_:)), name: .AVPlayerItemFailedToPlayToEndTime, object: self.player?.currentItem)
    }
    
    func releasePlayer() {
        player?.pause()
        player?.currentItem?.removeObserver(self, forKeyPath: status)
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: self.player?.currentItem)
        
        player = nil
    }
    
    @objc func itemDidPlayToEndTime(_ notification: NSNotification) {
        self.player?.seek(to: .zero)
    }
    
    @objc func itemFailedToPlayToEndTime(_ notification: NSNotification) {
        releasePlayer()
    }
    
    open override func observeValue(forKeyPath keyPath: String?,
                                          of object: Any?,
                                          change: [NSKeyValueChangeKey : Any]?,
                                          context: UnsafeMutableRawPointer?) {
        if keyPath == status, let state = self.player?.currentItem?.status, state == .failed {
            self.releasePlayer()
        }
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}
