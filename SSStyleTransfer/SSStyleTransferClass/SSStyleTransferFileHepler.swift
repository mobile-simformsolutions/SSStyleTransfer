//
//  SSStyleTransferFileHepler.swift
//  SSStyleTransferDemo
//
//  Created by Sanya Pillai on 31/03/21.
//

import Foundation

class SSStyleTransferFileHepler {
    
    private static let folderName = "SSStyleTransfer"
    private static let fileName = "FilterVideo.mp4"
    private static let OriginalVideo = "OriginalVideo"
    
    class func createVideoFilePath(forVideoUrl url: URL) throws -> (URL?, URL?) {
        var videoOutputURL: URL?
        var originalPath: URL?
        do {
            let documentsPath = createFolderAtPath().relativePath as NSString
            videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent(fileName))
            removeURLIfNeeded(url: videoOutputURL!)
            originalPath = try copyOriginalVideoToDocumentDirectory(originalURL: url)
        } catch let error {
            throw error
        }
        return (videoOutputURL,originalPath)
    }

    private class func getDocumentDirectoryPath() -> URL {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let docURL = URL(string: documentsDirectory)!
        return docURL
    }
    
    private class func createFolderAtPath() -> URL {
        let dataPath = getDocumentDirectoryPath().appendingPathComponent(folderName)
        if !FileManager.default.fileExists(atPath: dataPath.absoluteString) {
            do {
                try FileManager.default.createDirectory(atPath: dataPath.absoluteString, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
        return dataPath
    }
    
    class func cleanUpDocumentDirectory() {
        let dataPath = getDocumentDirectoryPath().appendingPathComponent(folderName).relativePath as NSString
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: dataPath as String)
            for item in items {
                if item.contains("\(fileName).sb") {
                    try? FileManager.default.removeItem(at: URL(fileURLWithPath: dataPath.appendingPathComponent(item)))
                }
            }
        } catch let e {
            print(e.localizedDescription)
        }
    }
    
    private class func removeURLIfNeeded(url: URL) {
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: url.relativePath) {
                try fileManager.removeItem(at: url)
            }
        } catch {
            print("Failed to remove file")
        }
    }
    
    private class func copyOriginalVideoToDocumentDirectory(originalURL url: URL) throws -> URL {
        let dataPath = getDocumentDirectoryPath().appendingPathComponent(folderName).relativePath as NSString
        let newPath = URL(fileURLWithPath: dataPath.appendingPathComponent(OriginalVideo)).appendingPathExtension(url.pathExtension)
        do {
            removeURLIfNeeded(url: newPath)
            try FileManager.default.copyItem(at: url, to: newPath)
        
        } catch let e{
            throw SSStyleTransferErrorConstant.kFailedToCopyOriginalVideoURL(message: e.localizedDescription).foundationError
        }
        return newPath
    }
}
