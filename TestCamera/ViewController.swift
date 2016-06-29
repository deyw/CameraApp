//
//  ViewController.swift
//  TestCamera
//
//  Created by VLADISLAV TAIURSKIY on 28.06.16.
//  Copyright © 2016 Vladislav Taiurskiy. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    let captureVideoSession = AVCaptureSession()
    var currentDevice:AVCaptureDevice?
    var videoFileOutput:AVCaptureMovieFileOutput?
    var cameraPreviewLayer:AVCaptureVideoPreviewLayer?
    var isRecording = false
    var frontCam = true
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var flipCameraButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        view.bringSubviewToFront(recordButton)
        view.bringSubviewToFront(flipCameraButton)
        
        
        
        // Capture device image
        let screenWidth = Int(UIScreen.mainScreen().bounds.size.width)
        let captureDeviceImageName: String = "capture_device_\(screenWidth)w"
        
        let captureDeviceImage : UIImageView = {
            let imageView = UIImageView()
            
            imageView.image = UIImage(named: captureDeviceImageName)
            imageView.frame = CGRect(x: 0, y: 64, width: imageView.image!.size.width, height:  imageView.image!.size.height)
            imageView.contentMode = .ScaleAspectFit
            return imageView
        }()
        
        view.addSubview(captureDeviceImage)
        
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        self.initCamera()
    }
    
    
    
    
    // Blurred original video preview size
    func initCamera() {
        
        captureVideoSession.sessionPreset = AVCaptureSessionPresetMedium
        
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureVideoSession)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        cameraPreviewLayer?.frame = view.layer.frame
        cameraView.layer.addSublayer(cameraPreviewLayer!)
        
        let devices = AVCaptureDevice.devices()
        
        var frontCamera: AVCaptureDevice?
        var rearCamera: AVCaptureDevice?
        
        for device in devices {
            if (device.hasMediaType(AVMediaTypeVideo)) {
                
                if device.position == AVCaptureDevicePosition.Back {
                    rearCamera = device as? AVCaptureDevice
                }
                
                if device.position == AVCaptureDevicePosition.Front {
                    frontCamera = device as? AVCaptureDevice
                }
                
            }
        }
        
        
        
        var captureDeviceInput:AVCaptureDeviceInput
        
        
        
        print(self.frontCam)
        
        if self.frontCam  {
            do {
                print("capture by front camera")
                captureDeviceInput = try AVCaptureDeviceInput(device: frontCamera)
            } catch {
                print(error)
                return
            }
            self.captureVideoSession.addInput(captureDeviceInput)
        }
        
        
        if !self.frontCam  {
            do {
                print("capture by back camera")
                captureDeviceInput = try AVCaptureDeviceInput(device: rearCamera)
            } catch {
                print(error)
                return
            }
            self.captureVideoSession.addInput(captureDeviceInput)
        }
        
        
        
        
        let blurEffect = UIBlurEffect(style: .Dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.bounds
        
        
        self.cameraView.addSubview(blurEffectView)
        self.captureVideoSession.startRunning()
        
    }
    
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        return
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        return
    }
    
    
    
    @IBAction func flipCamera(sender: AnyObject) {
        
        for input in captureVideoSession.inputs {
            captureVideoSession.removeInput(input as! AVCaptureInput)
        }
        
        if  frontCam {
            let imageRear = UIImage(named: "ic_camera_front_white")
            flipCameraButton.setImage(imageRear, forState: .Normal)
            frontCam = false
            self.initCamera()
        } else {
            let imageFront = UIImage(named: "ic_camera_rear_white")
            flipCameraButton.setImage(imageFront, forState: .Normal)
            frontCam = true
            self.initCamera()
        }
        
    }
    
    
    @IBAction func captureVideo(sender: AnyObject) {
        if !isRecording {
            isRecording = true
        }
        
        let recordingDelegate:AVCaptureFileOutputRecordingDelegate? = self
        let videoFileOutput = AVCaptureMovieFileOutput()
        
        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        let filePath = documentsURL.URLByAppendingPathComponent("temp")
        
        videoFileOutput.startRecordingToOutputFileURL(filePath, recordingDelegate: recordingDelegate)
    }
    
    
    
    
}

