//
//  ViewController.swift
//  VideoAndImageCapture
//
//  Created by HasegawaYasuo on 2018/08/22.
//  Copyright © 2018年 HasegawaYasuo. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class ViewController: UIViewController {
    var videoImageCapture:VideoAndImageCapture? = nil;
    var cameraView :UIView!
    
    var startButton, stopButton, imgCaptureButton : UIButton!
    var isRecording = false
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.cameraView = UIView();
        self.cameraView.frame = self.view.bounds;
        self.view.addSubview(self.cameraView)
        
        videoImageCapture = VideoAndImageCapture(view: self.cameraView)
        
        self.setupButton()
    }
    
    func setupButton(){
        self.startButton = UIButton(frame: CGRect(x: 0, y: 0, width: 80, height: 150))
        self.startButton.backgroundColor = UIColor.red;
        self.startButton.layer.masksToBounds = true
        self.startButton.setTitle("start", for: .normal)
        self.startButton.layer.cornerRadius = 20.0
        self.startButton.layer.position = CGPoint(x: self.view.bounds.width/2 - 110, y:self.view.bounds.height-50)
        self.startButton.addTarget(self, action: #selector(onClickStartButton(_:)), for: .touchUpInside)
        
        self.stopButton = UIButton(frame: CGRect(x: 0, y: 0, width: 80, height: 150))
        self.stopButton.backgroundColor = UIColor.gray;
        self.stopButton.layer.masksToBounds = true
        self.stopButton.setTitle("stop", for: .normal)
        self.stopButton.layer.cornerRadius = 20.0
        
        self.stopButton.layer.position = CGPoint(x: self.view.bounds.width/2, y:self.view.bounds.height-50)
        self.stopButton.addTarget(self, action: #selector(onClickStopButton(_:)), for: .touchUpInside)
        
        self.imgCaptureButton = UIButton(frame: CGRect(x: 0, y: 0, width: 80, height: 150))
        self.imgCaptureButton.backgroundColor = UIColor.blue;
        self.imgCaptureButton.layer.masksToBounds = true
        self.imgCaptureButton.setTitle("img", for: .normal)
        self.imgCaptureButton.layer.cornerRadius = 20.0
        
        self.imgCaptureButton.layer.position = CGPoint(x: self.view.bounds.width/2 + 110, y:self.view.bounds.height-50)
        self.imgCaptureButton.addTarget(self, action: #selector(onClickImgCaptureButton(_:)), for: .touchUpInside)
        
        self.view.addSubview(self.startButton);
        self.view.addSubview(self.stopButton);
        self.view.addSubview(self.imgCaptureButton);
    }
    
    @objc func onClickStartButton(_ sender: UIButton){
        if !self.isRecording {
            
            self.videoImageCapture?.start();
            
            self.isRecording = true
            self.changeButtonColor(target: self.startButton, color: UIColor.gray)
            self.changeButtonColor(target: self.stopButton, color: UIColor.red)
        }
    }
    
    @objc func onClickStopButton(_ sender: UIButton){
        if self.isRecording {
            
            self.videoImageCapture?.stop();
            
            self.isRecording = false
            self.changeButtonColor(target: self.startButton, color: UIColor.red)
            self.changeButtonColor(target: self.stopButton, color: UIColor.gray)
        }
    }
    
    @objc func onClickImgCaptureButton(_ sender: UIButton){
        self.videoImageCapture?.captureImage();
    }
    
    func changeButtonColor(target: UIButton, color: UIColor){
        target.backgroundColor = color
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

