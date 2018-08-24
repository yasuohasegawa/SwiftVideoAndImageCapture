//
//  VideoAndImageCapture.swift
//  VideoAndImageCapture
//
//  Created by HasegawaYasuo on 2018/08/22.
//  Copyright © 2018年 HasegawaYasuo. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class VideoAndImageCapture: NSObject,AVCaptureVideoDataOutputSampleBufferDelegate {
    let captureSession = AVCaptureSession()
    let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
    var videoOutput = AVCaptureVideoDataOutput()
    var view:UIView
    
    var videoWriter : VideoWriter?
    var isCapturing = false
    var isPaused = false
    
    var fileName = "temp"
    let videoWriterQueue = DispatchQueue(label: "com.VideoAndImageCapture.writer")
    let imgCaptureQueue = DispatchQueue(label: "com.VideoAndImageCapture.imgCapture")
    var fileURL : NSURL!
    var captureImg:UIImage!
    
    required init(view:UIView)
    {
        self.view=view
        super.init()
        self.initialize()
    }
    
    func initialize()
    {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filePath : String? = "\(documentsDirectory)/"+fileName+".mp4"
        fileURL = NSURL(fileURLWithPath: filePath!)
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: self.videoDevice!) as AVCaptureDeviceInput
            self.captureSession.addInput(videoInput)
        } catch let error as NSError {
            print(error)
        }
        
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String : Int(kCVPixelFormatType_32BGRA)]
        
        let queue:DispatchQueue = DispatchQueue(label: "myqueue", attributes: .concurrent)
        self.videoOutput.setSampleBufferDelegate(self, queue: queue)
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        
        self.captureSession.addOutput(self.videoOutput)
        
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        self.view.layer.addSublayer(videoLayer)
        
        for connection in self.videoOutput.connections {
            let conn = connection
            if conn.isVideoOrientationSupported {
                conn.videoOrientation = AVCaptureVideoOrientation.portrait
            }
        }
        
        self.captureSession.startRunning()
    }
    
    func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage {
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        let imageRef = context!.makeImage()
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let resultImage: UIImage = UIImage(cgImage: imageRef!)
        return resultImage
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        // メインスレッドで、バッファーを、UIImageに、変換したり、一度、同期させる。
        DispatchQueue.main.sync(execute: {
            // バッファーをUIImageに変換、画像キャプチャー用
            self.captureImg = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
        })
        
        // サブスレッドでの、処理
        self.videoWriterQueue.sync() {
            if !self.isCapturing || self.isPaused {
                return
            }
            
            let isVideo = output is AVCaptureVideoDataOutput
            
            if self.videoWriter == nil && isVideo {
                //print("setup video writer")
                self.videoWriter = VideoWriter(
                    fileUrl: fileURL
                )
            }
            
            if self.videoWriter != nil{
                //print("recording!\(isVideo)")
                self.videoWriter?.write(sample: sampleBuffer, isVideo: isVideo)
            }
        }
    }
    
    func start(){
        self.videoWriterQueue.sync() {
            if !self.isCapturing{
                self.isPaused = false
                self.isCapturing = true
            }
        }
    }
    
    func stop(){
        self.videoWriterQueue.sync() {
            if self.isCapturing{
                self.isCapturing = false
                //print("stop!")
                self.videoWriter!.finish { () -> Void in
                    
                    self.videoWriter = nil
                    
                }
            }
        }
    }
    
    func captureImage() {
        if self.captureImg == nil {
            return
        }
        
        self.imgCaptureQueue.sync() {
            let pngImageData = UIImagePNGRepresentation(self.captureImg)
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentsDirectory = paths[0] as String
            let filePath : String? = "\(documentsDirectory)/"+fileName+".png"
            do {
                try pngImageData!.write(to: URL(fileURLWithPath: filePath!), options: .atomic)
            } catch {
                print(error)
            }
        }
    }
    
}
