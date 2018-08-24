//
//  ViewController.swift
//  VideoAndImageCaptureDesktop
//
//  Created by HasegawaYasuo on 2018/08/24.
//  Copyright © 2018年 HasegawaYasuo. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    var videoImageCapture:VideoImageCapture? = nil;
    var cameraView :NSView!
    var startButton, stopButton, imgCaptureButton : NSButton!
    var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cameraView = NSView()
        self.cameraView.frame = self.view.bounds;
        self.view.addSubview(self.cameraView)
        
        videoImageCapture = VideoImageCapture(view: self.cameraView)
        
        self.setupButton()
        
        print("self.view.bounds: \(self.view.bounds)");
        
        // Do any additional setup after loading the view.
    }
    
    func setupButton(){
        self.startButton = NSButton(frame: CGRect(x: self.view.bounds.width/2 - (110+40), y:0, width: 80, height: 150))
        self.startButton.layer?.backgroundColor = NSColor.red.cgColor
        self.startButton.layer?.masksToBounds = true
        self.startButton.title = "start"
        self.startButton.layer?.cornerRadius = 20.0
        //self.startButton.layer?.position = CGPoint(x: self.view.bounds.width/2 - 110, y:self.view.bounds.height-50)
        self.startButton.target = self
        self.startButton.action = #selector(onClickStartButton(_:))
        
        self.stopButton = NSButton(frame: CGRect(x: self.view.bounds.width/2-40, y:0, width: 80, height: 150))
        self.startButton.layer?.backgroundColor = NSColor.gray.cgColor
        self.stopButton.layer?.masksToBounds = true
        self.stopButton.title = "stop"
        self.stopButton.layer?.cornerRadius = 20.0
        //self.stopButton.layer?.position = CGPoint(x: self.view.bounds.width/2, y:self.view.bounds.height-50)
        self.stopButton.target = self
        self.stopButton.action = #selector(onClickStopButton(_:))
        
        self.imgCaptureButton = NSButton(frame: CGRect(x: self.view.bounds.width/2 + (110-40), y:0, width: 80, height: 150))
        self.startButton.layer?.backgroundColor = NSColor.blue.cgColor
        self.imgCaptureButton.layer?.masksToBounds = true
        self.imgCaptureButton.title = "img"
        self.imgCaptureButton.layer?.cornerRadius = 20.0
        //self.imgCaptureButton.layer?.position = CGPoint(x: self.view.bounds.width/2 + 110, y:self.view.bounds.height-50)
        self.imgCaptureButton.target = self
        self.imgCaptureButton.action = #selector(onClickImgCaptureButton(_:))
        
        self.view.addSubview(self.startButton);
        self.view.addSubview(self.stopButton);
        self.view.addSubview(self.imgCaptureButton);
    }
    
    @objc func onClickStartButton(_ sender: NSButton){
        if !self.isRecording {
            
            self.videoImageCapture?.start();
            print("start")
            self.isRecording = true
            self.changeButtonColor(target: self.startButton, color: NSColor.gray.cgColor)
            self.changeButtonColor(target: self.stopButton, color: NSColor.red.cgColor)
        }
    }
    
    @objc func onClickStopButton(_ sender: NSButton){
        if self.isRecording {
            
            self.videoImageCapture?.stop();
            print("stop")
            self.isRecording = false
            self.changeButtonColor(target: self.startButton, color: NSColor.red.cgColor)
            self.changeButtonColor(target: self.stopButton, color: NSColor.gray.cgColor)
        }
    }
    
    @objc func onClickImgCaptureButton(_ sender: NSButton){
        self.videoImageCapture?.captureImage();
    }
    
    func changeButtonColor(target: NSButton, color: CGColor){
        target.layer?.backgroundColor = color
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

