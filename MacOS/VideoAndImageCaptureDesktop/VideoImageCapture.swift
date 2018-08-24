//
//  VideoImageCapture.swift
//  VideoAndImageCaptureDesktop
//
//  Created by HasegawaYasuo on 2018/08/22.
//  Copyright © 2018年 HasegawaYasuo. All rights reserved.
//

import Cocoa
import AVFoundation
import Photos

extension FileManager.SearchPathDirectory {
    func createSubFolder(named: String, withIntermediateDirectories: Bool = false) -> Bool {
        guard let url = FileManager.default.urls(for: self, in: .userDomainMask).first else { return false }
        do {
            try FileManager.default.createDirectory(at: url.appendingPathComponent(named), withIntermediateDirectories: withIntermediateDirectories, attributes: nil)
            return true
        } catch let error as NSError {
            print(error.description)
            return false
        }
    }
}

extension NSImage {
    var toCGImage: CGImage {
        var imageRect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        #if swift(>=3.0)
            guard let image =  cgImage(forProposedRect: &imageRect, context: nil, hints: nil) else {
                abort()
            }
        #else
            guard let image = CGImageForProposedRect(&imageRect, context: nil, hints: nil) else {
            abort()
            }
        #endif
        return image
    }
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}

extension CGImage {
    var size: CGSize {
        #if swift(>=3.0)
        #else
            let width = CGImageGetWidth(self)
            let height = CGImageGetHeight(self)
        #endif
        return CGSize(width: width, height: height)
    }
    
    var toNSImage: NSImage {
        #if swift(>=3.0)
            return NSImage(cgImage: self, size: size)
        #else
            return NSImage(CGImage: self, size: size)
        #endif
    }
}

class VideoImageCapture: NSObject,AVCaptureVideoDataOutputSampleBufferDelegate {
    static var saveDir:String = "videoAndImageSavedData"
    let captureSession = AVCaptureSession()
    var videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
    var videoOutput = AVCaptureVideoDataOutput()
    var view:NSView
    
    var videoWriter : VideoWriter?
    var isCapturing = false
    var isPaused = false
    
    let videoWriterQueue = DispatchQueue(label: "com.spicam.mock.writer")
    let imgCaptureQueue = DispatchQueue(label: "com.spicam.mock.imgCapture")
    var fileURL : NSURL!
    var captureImg:NSImage!
    
    required init(view:NSView)
    {
        self.view=view
        super.init()
        
        let devices = AVCaptureDevice.devices()
        // ここで、認識させたいカメラを探す Capabilities>App SandBoxで、camera/USBなど、必要な、項目に、チェック入れないと動かないので、注意
        for device in devices {
            print(device)
            
            if ((device as AnyObject).hasMediaType(AVMediaType.video)) {
                print(device)
                videoDevice = device
            }
        }
        
        self.initialize()
    }
    
    func initialize()
    {
        let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)
        let desktopDirectory = paths[0] as String
        let filePath : String? = "\(desktopDirectory)/\(VideoImageCapture.saveDir)/temp.mp4"
        fileURL = NSURL(fileURLWithPath: filePath!)
        
        print(fileURL)
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: self.videoDevice!) as AVCaptureDeviceInput
            self.captureSession.addInput(videoInput)
        } catch let error as NSError {
            print(error)
        }
        
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String : Int(kCVPixelFormatType_32BGRA)]
        
        // フレーム毎に呼び出すデリゲート登録
        let queue:DispatchQueue = DispatchQueue(label: "myqueue", attributes: .concurrent)
        self.videoOutput.setSampleBufferDelegate(self, queue: queue)
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        
        self.captureSession.addOutput(self.videoOutput)
        
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        self.view.layer?.addSublayer(videoLayer)
        
        //カメラ向き
        for connection in self.videoOutput.connections {
            let conn = connection
            if conn.isVideoOrientationSupported {
                conn.videoOrientation = AVCaptureVideoOrientation.portrait
            }
        }
        
        self.captureSession.startRunning()
    }
    
    func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> NSImage {
        //バッファーをUIImageに変換
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
        let resultImage: NSImage = imageRef!.toNSImage
        return resultImage
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        // メインスレッドで、バッファーを、NSImageに、変換したり、一度、同期させる。
        DispatchQueue.main.sync(execute: {
            // バッファーをNSImageに変換
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
                    
                    // 動画書き込み終了
                    print("mp4 saved!")
                }
            }
        }
    }
    
    func captureImage() {
        if self.captureImg == nil {
            return
        }
        
        self.imgCaptureQueue.sync() {
            let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)
            let desktopDirectory = paths[0] as String
            let filePath : String? = "\(desktopDirectory)/\(VideoImageCapture.saveDir)/temp.png"
            if self.captureImg.pngWrite(to: URL(fileURLWithPath: filePath!), options: .withoutOverwriting) {
                print("File saved")
            }
        }
    }
    
}
