//
//  VideoWriter.swift
//  VideoAndImageCaptureDesktop
//
//  Created by HasegawaYasuo on 2018/08/24.
//  Copyright © 2018年 HasegawaYasuo. All rights reserved.
//

import Foundation
import AVFoundation

class VideoWriter : NSObject{
    var fileWriter: AVAssetWriter!
    var videoInput: AVAssetWriterInput!
    
    init(fileUrl:NSURL!){
        
        let fileManager = FileManager.default
        let myDesktop = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first!
        guard let filePaths = try? fileManager.contentsOfDirectory(at: myDesktop, includingPropertiesForKeys: nil, options: []) else { return }
        for filePath in filePaths {
            if filePath.absoluteString.contains(VideoImageCapture.saveDir) {
                print(filePath)
                try? fileManager.removeItem(at: filePath)
            }
        }
        
        if FileManager.SearchPathDirectory.desktopDirectory.createSubFolder(named: VideoImageCapture.saveDir) {
            print("folder successfully created")
        }
        
        fileWriter = try? AVAssetWriter(outputURL: fileUrl as URL, fileType: .mov)
        
        // サイズは、とりあえず。
        let videoOutputSettings: Dictionary<String, AnyObject> = [
            AVVideoCodecKey : AVVideoCodecH264 as AnyObject,
            AVVideoWidthKey : 1280 as AnyObject,
            AVVideoHeightKey : 720 as AnyObject,
            AVVideoCompressionPropertiesKey : [
                AVVideoAverageBitRateKey : 2300000,
                ] as AnyObject
        ]
        
        videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
        videoInput.expectsMediaDataInRealTime = true
        fileWriter.add(videoInput)
    }
    
    func write(sample: CMSampleBuffer, isVideo: Bool){
        if CMSampleBufferDataIsReady(sample) {
            if fileWriter.status == AVAssetWriterStatus.unknown {
                print("Start writing, isVideo = \(isVideo), status = \(fileWriter.status.rawValue)")
                let startTime = CMSampleBufferGetPresentationTimeStamp(sample)
                fileWriter.startWriting()
                fileWriter.startSession(atSourceTime: startTime)
            } else {
                if videoInput.isReadyForMoreMediaData {
                    videoInput.append(sample)
                }
            }
        }
    }
    
    func finish(callback: @escaping () -> Void){
        fileWriter.finishWriting(completionHandler: callback)
    }
}
