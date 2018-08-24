//
//  VideoWritter.swift
//  VideoAndImageCapture
//
//  Created by HasegawaYasuo on 2018/08/22.
//  Copyright © 2018年 HasegawaYasuo. All rights reserved.
//

import Foundation
import AVFoundation
import AssetsLibrary

class VideoWriter : NSObject{
    var fileWriter: AVAssetWriter!
    var videoInput: AVAssetWriterInput!
    var width = 720;
    var height = 1280;
    
    init(fileUrl:NSURL!){
        let fileManager = FileManager.default
        let myDocuments = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        guard let filePaths = try? fileManager.contentsOfDirectory(at: myDocuments, includingPropertiesForKeys: nil, options: []) else { return }
        for filePath in filePaths {
            try? fileManager.removeItem(at: filePath)
        }
        
        fileWriter = try? AVAssetWriter(outputURL: fileUrl as URL, fileType: .mov)
        
        // サイズは、とりあえず。
        let videoOutputSettings: Dictionary<String, AnyObject> = [
            AVVideoCodecKey : AVVideoCodecType.h264 as AnyObject,
            AVVideoWidthKey : width as AnyObject,
            AVVideoHeightKey : height as AnyObject,
            AVVideoCompressionPropertiesKey : [
                AVVideoAverageBitRateKey : 2300000,
            ] as AnyObject
        ];
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
                videoInput.append(sample)
            }
        }
    }
    
    func finish(callback: @escaping () -> Void){
        fileWriter.finishWriting(completionHandler: callback)
    }
}
