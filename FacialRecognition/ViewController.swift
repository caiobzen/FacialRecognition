//
//  ViewController.swift
//  FacialRecognition
//
//  Created by Fumitoshi Ogata on 2014/06/30.
//  Copyright (c) 2014年 Fumitoshi Ogata. All rights reserved.
//

import UIKit
import CoreImage
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet var imageView : UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)

        
        
        do
        {
            let input = try AVCaptureDeviceInput(device: backCamera)
            captureSession.addInput(input)
        }
        catch
        {
            print("can't access camera")
            return
        }
        
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        
        let videoOutput = AVCaptureVideoDataOutput()
        
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample buffer delegate", DISPATCH_QUEUE_SERIAL))
        if captureSession.canAddOutput(videoOutput)
        {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.startRunning()
        
    }
    
    
    func applyFilter() {
        //Filter
        if let image = imageView.image {
            
            let ciImage  = image.CIImage
            let ciDetector = CIDetector(ofType:CIDetectorTypeFace
                ,context:nil
                ,options:[
                    CIDetectorAccuracy:CIDetectorAccuracyHigh,
                    CIDetectorSmile:true
                ]
            )
            let features = ciDetector.featuresInImage(ciImage!)
            
            UIGraphicsBeginImageContext(imageView.image!.size)
            imageView.image!.drawInRect(CGRectMake(0,0,imageView.image!.size.width,imageView.image!.size.height))
            
            for feature in features{
                
                if let feat = feature as? CIFaceFeature {
                    //context
                    let drawCtxt = UIGraphicsGetCurrentContext()
                    
                    //face
                    var faceRect = (feature as! CIFaceFeature).bounds
                    faceRect.origin.y = imageView.image!.size.height - faceRect.origin.y - faceRect.size.height
                    CGContextSetStrokeColorWithColor(drawCtxt, UIColor.redColor().CGColor)
                    CGContextStrokeRect(drawCtxt,faceRect)
                    
                    //mouse
                    if(feat.hasMouthPosition){
                        let mouseRectY = imageView.image!.size.height - feat.mouthPosition.y
                        let mouseRect  = CGRectMake(feat.mouthPosition.x - 5,mouseRectY - 5,10,10)
                        CGContextSetStrokeColorWithColor(drawCtxt,UIColor.blueColor().CGColor)
                        CGContextStrokeRect(drawCtxt,mouseRect)
                    }
                    
                    //hige
                    let higeImg      = UIImage(named:"hige_100.png")?.imageRotatedByDegrees(180, flip: false)
                    let mouseRectY = imageView.image!.size.height - feat.mouthPosition.y
                    //ヒゲの横幅は顔の4/5程度
                    let higeWidth  = faceRect.size.width * 4/5
                    let higeHeight = higeWidth * 0.3 // 元画像が100:30なのでWidthの30%が縦幅
                    let higeRect  = CGRectMake(feat.mouthPosition.x - higeWidth/2,mouseRectY - higeHeight,higeWidth,higeHeight)
                    CGContextDrawImage(drawCtxt,higeRect,higeImg!.CGImage)
                    
                    //leftEye
                    if(feat.hasLeftEyePosition){
                        let leftEyeRectY = imageView.image!.size.height - feat.leftEyePosition.y
                        let leftEyeRect  = CGRectMake(feat.leftEyePosition.x - 5,leftEyeRectY - 5,10,10)
                        CGContextSetStrokeColorWithColor(drawCtxt, UIColor.blueColor().CGColor)
                        CGContextStrokeRect(drawCtxt,leftEyeRect)
                    }
                    
                    //rightEye
                    if(feat.hasRightEyePosition){
                        let rightEyeRectY = imageView.image!.size.height - feat.rightEyePosition.y
                        let rightEyeRect  = CGRectMake(feat.rightEyePosition.x - 5,rightEyeRectY - 5,10,10)
                        CGContextSetStrokeColorWithColor(drawCtxt, UIColor.blueColor().CGColor)
                        CGContextStrokeRect(drawCtxt,rightEyeRect)
                    }
                    
                }
            }
            let drawedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            imageView.image = drawedImage
        }
    }
        
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!)
    {
        connection.videoOrientation = .Portrait

        dispatch_async(dispatch_get_main_queue()) { [unowned self] in
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            let cameraImage = CIImage(CVPixelBuffer: pixelBuffer!)
            
            let image = UIImage(CIImage: cameraImage)
            self.imageView.image = image
            
            self.applyFilter()
        }
       
    }
}



import UIKit

extension UIImage {
    public func imageRotatedByDegrees(degrees: CGFloat, flip: Bool) -> UIImage {
        let radiansToDegrees: (CGFloat) -> CGFloat = {
            return $0 * (180.0 / CGFloat(M_PI))
        }
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(M_PI)
        }
        
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPointZero, size: size))
        let t = CGAffineTransformMakeRotation(degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width / 2.0, rotatedSize.height / 2.0);
        
        //   // Rotate the image context
        CGContextRotateCTM(bitmap, degreesToRadians(degrees));
        
        // Now, draw the rotated/scaled image into the context
        var yFlip: CGFloat
        
        if(flip){
            yFlip = CGFloat(-1.0)
        } else {
            yFlip = CGFloat(1.0)
        }
        
        CGContextScaleCTM(bitmap, yFlip, -1.0)
        CGContextDrawImage(bitmap, CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height), CGImage)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}