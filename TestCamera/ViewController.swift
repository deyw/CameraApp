//
//  ViewController.swift
//  TestCamera
//
//  Created by VLADISLAV TAIURSKIY on 28.06.16.
//  Copyright © 2016 Vladislav Taiurskiy. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    let captureVideoSession = AVCaptureSession()
    var videoFileOutput:AVCaptureMovieFileOutput?
    var cameraPreviewLayer:AVCaptureVideoPreviewLayer?
    var isRecording = false
    var frontCam = true
    var photosAsset: PHFetchResult!
    var assetCollection: PHAssetCollection!
    var assetCollectionPlaceholder: PHObjectPlaceholder!
    var albumFound : Bool = false
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var cropCameraView: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var flipCameraButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        view.bringSubviewToFront(recordButton)
        view.bringSubviewToFront(flipCameraButton)
        
        createAlbum()
        
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
    
    
    func createAlbum() {
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "TestCam")
        let collection : PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
        
        
        //Check return value - If found, then get the first album out
        if let _: AnyObject = collection.firstObject {
            self.albumFound = true
            assetCollection = collection.firstObject as! PHAssetCollection
        } else {
            
            //If not found - Then create a new album
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                let createAlbumRequest : PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle("TestCam")
                self.assetCollectionPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
                }, completionHandler: { success, error in
                    self.albumFound = (success ? true: false)
                    
                    if (success) {
                        let collectionFetchResult = PHAssetCollection.fetchAssetCollectionsWithLocalIdentifiers([self.assetCollectionPlaceholder.localIdentifier], options: nil)
                        print(collectionFetchResult)
                        self.assetCollection = collectionFetchResult.firstObject as! PHAssetCollection
                    }
            })
        }
    }
    
    
    
    
    func initCamera() {
        
        captureVideoSession.sessionPreset = AVCaptureSessionPresetHigh
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureVideoSession)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        cameraPreviewLayer?.frame = cropCameraView.bounds
        
        cropCameraView.layer.addSublayer(cameraPreviewLayer!)
        
                
        
        
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
        
        
        
        print(frontCam)
        
        if frontCam  {
            do {
                print("capture by front camera")
                captureDeviceInput = try AVCaptureDeviceInput(device: frontCamera)
            } catch {
                print(error)
                return
            }
            captureVideoSession.addInput(captureDeviceInput)
            
        }
        
        if !frontCam  {
            do {
                print("capture by back camera")
                captureDeviceInput = try AVCaptureDeviceInput(device: rearCamera)
            } catch {
                print(error)
                return
            }
            captureVideoSession.addInput(captureDeviceInput)
            
        }
        
        
        
        
        let blurEffect = UIBlurEffect(style: .Dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        
        cameraView.addSubview(blurEffectView)
        captureVideoSession.startRunning()
        videoFileOutput = AVCaptureMovieFileOutput()
        
        
        
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
            recordButton.setTitle("Stop", forState: .Normal)
            
            
            captureVideoSession.addOutput(self.videoFileOutput)
            
            let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
            let documentsDirectory = paths[0] as String
            let movieFileName = "movie_temp.mp4"
            let filePath : String? = "\(documentsDirectory)/\(movieFileName)"
            let fileURL : NSURL = NSURL(fileURLWithPath: filePath!)
            
            videoFileOutput!.startRecordingToOutputFileURL(fileURL, recordingDelegate: self)
            
            
            
            
        } else {
            recordButton.setTitle("Record", forState: .Normal)
            
            for videoFileOutput in captureVideoSession.outputs {
                captureVideoSession.removeOutput(videoFileOutput as? AVCaptureOutput)
            }
            
            self.videoFileOutput?.stopRecording()
            isRecording = false
        }
        
        
    }
    
    // start capture
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        return
    }
    
    // finish capture
    // Save video to application album
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        
        
        // Trying to make and save square(300x300) video
        let asset : AVURLAsset = AVURLAsset(URL: outputFileURL, options: nil)
        if let clipVideoTrack: AVAssetTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0]
        {
            
            let videoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
            videoComposition.frameDuration = CMTimeMake(1, 60)
            
            print(clipVideoTrack.naturalSize.height)
            
            videoComposition.renderSize = CGSizeMake(clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.height)

            
            let instruction: AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30))
            let transformer: AVMutableVideoCompositionLayerInstruction =
                AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)
            
            let t1: CGAffineTransform = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, -(clipVideoTrack.naturalSize.width - clipVideoTrack.naturalSize.height) / 2 - 60)
            
            let t2: CGAffineTransform = CGAffineTransformRotate(t1, CGFloat(M_PI_2))
            
            let finalTransform: CGAffineTransform = t2
            
            transformer.setTransform(finalTransform, atTime: kCMTimeZero)
           
            instruction.layerInstructions = NSArray(object: transformer) as! [AVVideoCompositionLayerInstruction]
            videoComposition.instructions = NSArray(object: instruction) as! [AVVideoCompositionInstructionProtocol]
            
            let exportPath : NSString = NSString(format: "%@%@", NSTemporaryDirectory(), "\(randomStringWithLength(5)).mov")
            
            let exportUrl: NSURL = NSURL.fileURLWithPath(exportPath as String)
           
            
            let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
            exporter!.videoComposition = videoComposition
            exporter!.outputFileType = AVFileTypeQuickTimeMovie
            exporter!.outputURL = exportUrl
            exporter!.exportAsynchronouslyWithCompletionHandler({ () -> Void in
              
             let outputURL:NSURL = exporter!.outputURL!;
                
                
                PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                    let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(outputURL)
                    let assetPlaceholder = assetRequest!.placeholderForCreatedAsset
                    self.photosAsset = PHAsset.fetchAssetsInAssetCollection(self.assetCollection, options: nil)
                    let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: self.assetCollection, assets: self.photosAsset)
                    albumChangeRequest!.addAssets([assetPlaceholder!])
                    
                    
                    
                    }, completionHandler: { (success, error) in
                        if success {
                            print("added video to album")
                        } else if error != nil{
                            print("handle error since couldn't save video")
                        }
                })
                
                                
            })
            
        }
        return
    }
    
    
    func randomStringWithLength (len : Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        
        for _ in 0..<len {
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString
    }
    
    
    
    
}

