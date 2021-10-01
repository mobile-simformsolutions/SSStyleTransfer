//
//  SSStyleTransferFilter.swift
//  SSStyleTransferDemo
//
//  Created by Sanya Pillai on 31/03/21.
//

import UIKit
import Vision
import AVFoundation

@objc public protocol SStyleTransferFilterDelegate: class {
    @objc optional func styleTransferFilter(didMakeProgress progress: Float)
    @objc optional func styleTransferFilter(didFinishWithURL url: URL)
    @objc optional func styleTransferFilter(didFailWithError error: Error)
    @objc optional func styleTransferFilterSave(didFinishSavingWithSuccess message:String, withError error: Error?)
}

//MARK: ML Models
public enum SSStyle: String,CaseIterable {
    case waterBlue
    case fieryFire
    case frozenBlack
    case frozenBlue
    case wavy
    case starryNights
}

class SSStyleTransferFilter: NSObject {
    
    //MARK: MLModel config properties
    public lazy var currentStyle: SSStyle = .waterBlue
    public lazy var modelComputeUnits: MLComputeUnits = .cpuAndGPU
    private var modelConfiguration = MLModelConfiguration()
    private var filterResultCallBack:((CVPixelBuffer?, UIImage?, NSError?) -> Void)?
    weak var styleTransferDelegte: SStyleTransferFilterDelegate?
    
    //MARK: AVAsset properties
    private lazy var mediaQueue = {
        return DispatchQueue(label: "mediaInputQueue")
    }()
    private var avAsset: AVAsset!
    private var videoWriter: AVAssetWriter?
    private var assetReader: AVAssetReader?
    private var videoWriterInput: AVAssetWriterInput?
    private var audioWriterInput: AVAssetWriterInput?
    private var assetReaderVideoOutput: AVAssetReaderTrackOutput!
    private var assetReaderAudioOutput: AVAssetReaderTrackOutput!
    private var assetWriterPixelBufferInputAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var endProcessingVideo: ((Error?) -> Void)?
    var videoOutputURL: URL?
    var audioFinished: Bool = false
    var videoFinished: Bool = false
    var workItem: DispatchWorkItem!
    
    override init() {
        super.init()
    }
    
    func applyFilterTo(image inputImage: UIImage, callBack: @escaping ((UIImage?,NSError?) -> Void)) {
        if let pxlBuffer = inputImage.pixelBufferFromImage() {
            self.applyFilterToPixel(pixelBuffer: pxlBuffer) { (pixelBuffer, outputImage, errorMsg) in
                if errorMsg != nil {
                    callBack(nil,errorMsg)
                    return
                }
                guard let image = outputImage else {
                    callBack(nil, SSStyleTransferErrorConstant.kFailedToRetrieveFilteredImage.foundationError)
                    return
                }
                let finalImage = image.resizeImage(targetSize: inputImage.size)
                callBack(finalImage, nil)
                
            } failure: { (err) in
                callBack(nil, err)
            }
        }
    }
    
    func applyAndSaveFilteredVideo(url: URL) {
        endProcessingVideo = { [weak self] (error) -> Void in
            guard let weakSelf = self else { return }
            if weakSelf.videoWriter?.status == .writing {
                weakSelf.videoWriter?.finishWriting {
                    print(weakSelf.videoOutputURL ?? "")
                    print("Completed")
                }
            }
            if error == nil {
                if let url = weakSelf.videoOutputURL {
                    DispatchQueue.main.async {
                        weakSelf.styleTransferDelegte?.styleTransferFilter?(didFinishWithURL: url)
                        weakSelf.endProcessingVideo = nil
                    }
                }
            } else {
                if let err = error {
                    weakSelf.styleTransferDelegte?.styleTransferFilter?(didFailWithError: err)
                    weakSelf.endProcessingVideo = nil
                }
            }
            weakSelf.filterResultCallBack = nil
            weakSelf.cleanupResources()
        }
        do {
            let (videoURL,originalPath) = try SSStyleTransferFileHepler.createVideoFilePath(forVideoUrl: url)
            guard (videoURL != nil),(originalPath != nil) else {
                endProcessingVideo?(SSStyleTransferErrorConstant.kVideoOutputUrlEmpty.foundationError)
                return
            }
            videoOutputURL = videoURL!
            setUpWriter(url: originalPath!)
        } catch let error {
            endProcessingVideo?(error)
        }
    }
    
    func cleanupResources() {
        avAsset = nil
        videoWriter = nil
        assetReader = nil
        videoWriterInput = nil
        audioWriterInput = nil
        assetReaderVideoOutput = nil
        assetReaderAudioOutput = nil
        assetWriterPixelBufferInputAdaptor = nil
        audioFinished = false
        videoFinished = false
        SSStyleTransferFileHepler.cleanUpDocumentDirectory()
    }
    
    func saveVideoToGallery() {
        guard let url = videoOutputURL else {
            print("Filtered Video URL not available")
            return
        }
        UISaveVideoAtPathToSavedPhotosAlbum(url.relativePath, self, #selector(saveVideo(videoPath:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func saveVideo(videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        if error == nil {
            styleTransferDelegte?.styleTransferFilterSave?(didFinishSavingWithSuccess: "Saved Video", withError: nil)
        } else {
            styleTransferDelegte?.styleTransferFilterSave?(didFinishSavingWithSuccess: "Unable to save video", withError: error)
        }
        
    }
    
    func savePhotoToGallery(photo: UIImage) {
        UIImageWriteToSavedPhotosAlbum(photo, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error == nil {
            styleTransferDelegte?.styleTransferFilterSave?(didFinishSavingWithSuccess: "Saved photo", withError: nil)
        } else {
            styleTransferDelegte?.styleTransferFilterSave?(didFinishSavingWithSuccess: "Unable to save photo", withError: error)
        }
    }
    
    func cancelFilter() {
        workItem.cancel()
        assetReader?.cancelReading()
        videoWriter?.cancelWriting()
        videoFinished = true
        audioFinished = true
        videoWriterInput?.markAsFinished()
        audioWriterInput?.markAsFinished()
    }
}

// ML Model Methods
extension SSStyleTransferFilter {
    
    func applyFilterToPixel(pixelBuffer: CVPixelBuffer, callBack: @escaping ((CVPixelBuffer?, UIImage?,NSError?) -> Void), failure: ((NSError) -> Void)) {
        
        filterResultCallBack = callBack
        modelConfiguration.computeUnits = modelComputeUnits
        guard let model = loadModel() else {
            return failure(SSStyleTransferErrorConstant.kFailedToLoadMLModel.foundationError)
        }
        do {
            let currentModel = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: currentModel) { [weak self] (request, error) in
                guard let weakSelf = self else { return }
                if (error == nil) {
                    guard let results = request.results as? [VNPixelBufferObservation] else { return }
                    guard let observation = results.first else { return }
                    let filterImage = UIImage(pixelBuffer: observation.pixelBuffer)
                    weakSelf.filterResultCallBack?(observation.pixelBuffer, filterImage,nil)
                } else {
                    print("Coreml error\(error.debugDescription)")
                    weakSelf.filterResultCallBack?(nil,nil, SSStyleTransferErrorConstant.kFailedToProcessMLRequest(message: error.debugDescription).foundationError)
                    return
                }
            }
            do {
                try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
            } catch let error {
                failure(SSStyleTransferErrorConstant.kFailedToApplyStyleToVideo(message: error.localizedDescription).foundationError)
            }
        } catch {
            failure(SSStyleTransferErrorConstant.kMLModelNotSupported.foundationError)
        }
    }
    
    private func loadModel() -> MLModel? {
        switch currentStyle {
        case .waterBlue:
            return try? SSWaterBlueStyle.init(configuration: modelConfiguration).model
        case .fieryFire:
            return try? SSFieryStyle.init(configuration: modelConfiguration).model
        case .frozenBlack:
            return try? SSFrozenBlackStyle.init(configuration: modelConfiguration).model
        case .frozenBlue:
            return try? SSFrozenBlueStyle.init(configuration: modelConfiguration).model
        case .wavy:
            return try? SSWavyStyle.init(configuration: modelConfiguration).model
        case .starryNights:
            return try? SSStaryNightsStyle.init(configuration: modelConfiguration).model
        }
    }
}

// Video Writer & reader methods
extension SSStyleTransferFilter {
    
    func setUpWriter(url: URL) {
        avAsset = AVAsset(url: url)
        guard let videoOutputURL = videoOutputURL else {
            endProcessingVideo?(SSStyleTransferErrorConstant.kVideoOutputUrlEmpty.foundationError)
            return
        }
        do {
            // Reader and Writer
            videoWriter = try AVAssetWriter(outputURL: videoOutputURL, fileType: AVFileType.mp4)
            assetReader = try AVAssetReader(asset: avAsset)
            
            // Video Track
            guard let videoTrack = avAsset.tracks(withMediaType: .video).first else {
                endProcessingVideo?(SSStyleTransferErrorConstant.kVideoTrackNotAvailable.foundationError)
                return
            }
            
            // Video Output Configuration
            let videoOutputSettings: Dictionary<String, Any> = [
                AVVideoWidthKey : videoTrack.naturalSize.width,
                AVVideoHeightKey : videoTrack.naturalSize.height,
                AVVideoCodecKey : AVVideoCodecType.h264,
            ]
            videoWriterInput = AVAssetWriterInput(mediaType: .video,outputSettings: videoOutputSettings)
            videoWriterInput?.expectsMediaDataInRealTime = false
            guard let videoWriterInput = self.videoWriterInput, let canAddInput = videoWriter?.canAdd(videoWriterInput),
                  canAddInput else {
                endProcessingVideo?(SSStyleTransferErrorConstant.kFailedToAddVideoOrAudioToInputWriter.foundationError)
                return
            }
            videoWriter?.add(videoWriterInput)
            let sourcePixelBufferAttributesDictionary: Dictionary<String, Any> = [
                String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_32RGBA),
            ]
            assetWriterPixelBufferInputAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
            videoWriterInput.performsMultiPassEncodingIfSupported = true
            
            // Video Input Configuration
            let videoOptions: Dictionary<String, Any> = [
                kCVPixelBufferPixelFormatTypeKey as String : UInt(kCVPixelFormatType_422YpCbCr8_yuvs),
                kCVPixelBufferIOSurfacePropertiesKey as String : [:]
            ]
            assetReaderVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoOptions)
            assetReaderVideoOutput.alwaysCopiesSampleData = true
            guard let reader = assetReader, reader.canAdd(assetReaderVideoOutput) else {
                endProcessingVideo?(SSStyleTransferErrorConstant.kFailedToAddVideoOrAudioToOutputReader.foundationError)
                return
            }
            reader.add(assetReaderVideoOutput)
            if !videoTrackHasAudio() {
                // Audio Track
                let audioTrack = avAsset.tracks(withMediaType: .audio).first!
                let audioOutputSettings: Dictionary<String, Any> = [
                    AVFormatIDKey : UInt(kAudioFormatMPEG4AAC),
                    AVNumberOfChannelsKey : UInt(2),
                    AVSampleRateKey : UInt(22050)
                ]
                audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOutputSettings)
                audioWriterInput?.expectsMediaDataInRealTime = false
                guard let audioWriterInput = self.audioWriterInput,
                      let canAddInput = videoWriter?.canAdd(audioWriterInput),
                      canAddInput else {
                    endProcessingVideo?(SSStyleTransferErrorConstant.kFailedToAddVideoOrAudioToInputWriter.foundationError)
                    return
                }
                videoWriter?.add(audioWriterInput)
                
                // Audio Input Configuration
                let decompressionAudioSettings: Dictionary<String, Any> = [
                    AVFormatIDKey: UInt(kAudioFormatLinearPCM)
                ]
                assetReaderAudioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: decompressionAudioSettings)
                assetReaderAudioOutput.alwaysCopiesSampleData = true
                guard let reader = assetReader, reader.canAdd(assetReaderAudioOutput)  else {
                    endProcessingVideo?(SSStyleTransferErrorConstant.kFailedToAddVideoOrAudioToOutputReader.foundationError)
                    return
                }
                reader.add(assetReaderAudioOutput)
                
            } else {
                audioFinished = true
            }
            
            assetReader!.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: avAsset.duration)
            videoWriter!.shouldOptimizeForNetworkUse = true
            assetReader!.startReading()
            videoWriter!.startWriting()
            videoWriter!.startSession(atSourceTime: CMTime.zero)
            startProcessing()
            
        } catch let writerError as NSError {
            endProcessingVideo?(SSStyleTransferErrorConstant.kAssetReaderWriterError(message: writerError.debugDescription).foundationError)
        }
    }
    
    func startProcessing() {
        guard let videoWriter = videoWriter,
              let assetReader = assetReader,
              let videoWriterInput = videoWriterInput,
              let frameRate = avAsset.tracks(withMediaType: .video).first?.nominalFrameRate else {
            print("empty error")
            return
        }
        var error: Error?
        let duration = self.avAsset.duration
        let numberOfFrames = Int(duration.seconds * Double(frameRate))
        var frameNumber = 0
        let dispatchGroup = DispatchGroup()
        workItem = DispatchWorkItem { [weak self] in
            guard let weakself = self else { return }
            while !weakself.videoFinished || !weakself.audioFinished {
                //Check for Writer Errors (out of storage etc.)
                if videoWriter.status == AVAssetWriter.Status.failed {
                    weakself.checkWriterError { (err) in
                        error = err
                    }
                    return
                }
                
                // Check for Reader Errors (source file corruption etc.)
                if assetReader.status == AVAssetReader.Status.failed {
                    weakself.checkReaderError { (err) in
                        error = err
                    }
                    return
                }
                
                // progress details
                DispatchQueue.main.async {
                    weakself.styleTransferDelegte?.styleTransferFilter?(didMakeProgress: (Float(frameNumber) * 100) / Float(numberOfFrames))
                }
                // Check if enough data is ready for encoding a single frame
                if videoWriterInput.isReadyForMoreMediaData {
                    // Copy a single frame from source to destination
                    if let vBuffer = weakself.assetReaderVideoOutput.copyNextSampleBuffer(), CMSampleBufferDataIsReady(vBuffer) {
                        frameNumber += 1
                        print("Encoding frame: \(frameNumber)")
                        weakself.startVideoProcessing(videoBuffer: vBuffer) { (err) in
                            error = err
                        }
                    } else {
                        // Video source is depleted, mark as finished
                        if !weakself.videoFinished {
                            videoWriterInput.markAsFinished()
                        }
                        if weakself.videoTrackHasAudio() {
                            weakself.audioFinished = true
                        }
                        weakself.videoFinished = true
                    }
                }
                
                if let audioInput = weakself.audioWriterInput, audioInput.isReadyForMoreMediaData {
                    // Copy a single audio sample from source to destination
                    if let aBuffer = weakself.assetReaderAudioOutput.copyNextSampleBuffer(), CMSampleBufferDataIsReady(aBuffer) {
                        _ = audioInput.append(aBuffer)
                    } else {
                        // Audio source is depleted, mark as finished
                        if !weakself.audioFinished {
                            audioInput.markAsFinished()
                        }
                        weakself.audioFinished = true
                    }
                }
                // Let background thread rest for a while
                Thread.sleep(forTimeInterval: 0.001)
            }
        }
        mediaQueue.async(group: dispatchGroup, execute: workItem)
        dispatchGroup.notify(queue: DispatchQueue.main) {  () -> Void in
            if self.audioFinished && self.videoFinished {
                if let closure = self.endProcessingVideo {
                    if self.workItem.isCancelled {
                        closure(SSStyleTransferErrorConstant.kFilteringCancelled.foundationError)
                    }
                    closure(error)
                }
            }
        }
    }
    
    func startVideoProcessing(videoBuffer: CMSampleBuffer,failure: ((Error) -> Void)) {
        autoreleasepool {
            let presentationTime = CMSampleBufferGetPresentationTimeStamp(videoBuffer)
            let pixelBuffer = CMSampleBufferGetImageBuffer(videoBuffer)!
            var error: Error?
            
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue:0))
            //apply coreml style filter to given pixel
            applyFilterToPixel(pixelBuffer: pixelBuffer) { (resultPixel, outputImage, errorMsg)  in
                if errorMsg != nil {
                    error = errorMsg
                    return
                }
                guard let image = outputImage else {
                    error = SSStyleTransferErrorConstant.kFailedToRetrieveFilteredImage.foundationError
                    return
                }
                if !self.appendPixelBufferFromFilteredImage(image, presentationTime: presentationTime) {
                    error = SSStyleTransferErrorConstant.kFailedToAppendPixelBufferError.foundationError
                    return
                }
                CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
                
            } failure: { (err) in
                error = err
            }
            
            if let err = error {
                failure(err)
            }
        }
    }
    
    private func appendPixelBufferFromFilteredImage(_ image: UIImage, presentationTime: CMTime) -> Bool {
        var appendSucceeded = false
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        if status == kCVReturnSuccess {
            if let assetWriterPixelBufferInputAdaptor = assetWriterPixelBufferInputAdaptor, let pxBuffer = pixelBuffer {
                fillPixelBufferFromImage(image, pixelBuffer: pxBuffer)
                appendSucceeded = assetWriterPixelBufferInputAdaptor.append(
                    pxBuffer,
                    withPresentationTime: presentationTime
                )
            }
        }
        return appendSucceeded
    }
    
    func fillPixelBufferFromImage(_ image: UIImage, pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: pixelData,
            width: Int(image.size.width),
            height: Int(image.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        context?.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    }
    
    func checkWriterError(error: ((Error) -> Void)) {
        assetReader?.cancelReading()
        videoWriter?.cancelWriting()
        if let e = videoWriter?.error {
            error(SSStyleTransferErrorConstant.kFailedToStartAssetWriterError(message: e.localizedDescription).foundationError)
        }
    }
    
    func checkReaderError(error: ((Error) -> Void)) {
        assetReader?.cancelReading()
        videoWriter?.cancelWriting()
        if let e = assetReader?.error {
            error(SSStyleTransferErrorConstant.kFailedToStartAssetReaderError(message: e.localizedDescription).foundationError)
        }
    }
    
    func videoTrackHasAudio() -> Bool {
        let hasAudio = avAsset.tracks(withMediaType: .audio)
        return hasAudio.isEmpty //will return true if audio is not available
    }
}
