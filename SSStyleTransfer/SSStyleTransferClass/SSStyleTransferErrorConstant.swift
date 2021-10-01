//
//  SSStyleTransferErrorConstant.swift
//  SSStyleTransferDemo
//
//  Created by Sanya Pillai on 31/03/21.
//

import Foundation

enum SSStyleTransferErrorConstant {
    case kVideoOutputUrlEmpty
    case kFailedToCopyOriginalVideoURL(message: String)
    case kAssetReaderWriterError(message: String)
    case kVideoTrackNotAvailable
    case kFailedToAddVideoOrAudioToInputWriter
    case kFailedToAddVideoOrAudioToOutputReader
    case kFailedToStartAssetWriterError(message: String)
    case kFailedToStartAssetReaderError(message: String)
    case kFailedToAppendPixelBufferError
    case kFailedToRetrieveFilteredImage
    case kFailedToLoadMLModel
    case kFailedToProcessMLRequest(message: String)
    case kFailedToApplyStyleToVideo(message: String)
    case kMLModelNotSupported
    case kFilteringCancelled
    
    private var kErrorDomain: String {
        return "com.simform.SSStyleTransfer"
    }
    private var errorCode: Int {
        switch self {
        case .kVideoOutputUrlEmpty:
            return 100
        case .kFailedToCopyOriginalVideoURL( _):
            return 101
        case .kAssetReaderWriterError( _):
            return 102
        case .kVideoTrackNotAvailable:
            return 103
        case .kFailedToAddVideoOrAudioToInputWriter:
            return 104
        case .kFailedToAddVideoOrAudioToOutputReader:
            return 105
        case .kFailedToStartAssetWriterError( _):
            return 106
        case .kFailedToStartAssetReaderError( _):
            return 107
        case .kFailedToAppendPixelBufferError:
            return 108
        case .kFailedToRetrieveFilteredImage:
            return 109
        case .kFailedToLoadMLModel:
            return 110
        case .kFailedToProcessMLRequest( _):
            return 111
        case .kFailedToApplyStyleToVideo( _):
            return 112
        case .kMLModelNotSupported:
            return 113
        case .kFilteringCancelled:
            return 114
        }
    }
    var description: String {
        switch self {
        case .kVideoOutputUrlEmpty:
            return "Output url is empty."
        case .kFailedToCopyOriginalVideoURL(let message):
            return "Failed to copy original video to document directory \(message)."
        case .kAssetReaderWriterError(let message):
            return "Failed to open asset \(message)."
        case .kVideoTrackNotAvailable:
            return "Video Track is not available in asset."
        case .kFailedToAddVideoOrAudioToInputWriter:
            return "Failed to add video or audio to input AVAssetWriter"
        case .kFailedToAddVideoOrAudioToOutputReader:
            return "Failed to add video or audio to output AVAssetReader"
        case .kFailedToStartAssetWriterError(let message):
            return "AVAssetWriter failed to start writing \(message)."
        case .kFailedToStartAssetReaderError(let message):
            return "AVAssetReader failed to start reading \(message)."
        case .kFailedToAppendPixelBufferError:
            return "AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer."
        case .kFailedToRetrieveFilteredImage:
            return "Failed to retrieve filtered image."
        case .kFailedToLoadMLModel:
            return "Failed to load CoreML Model."
        case .kFailedToProcessMLRequest(let message):
            return "Failed to process ML Request on video \(message)."
        case .kFailedToApplyStyleToVideo(let message):
            return "Failed to apply ML filter to video \(message)."
        case .kMLModelNotSupported:
            return "Core ML model is not supported."
        case .kFilteringCancelled:
            return "Filtering is cancelled"
        }
    }
    var foundationError: NSError {
        return NSError(domain: kErrorDomain, code: errorCode, userInfo: [
            NSLocalizedDescriptionKey : description
        ])
    }
}
