//
//  CaptureViewController.swift
//  FutureRecords
//
//  Created by Карпенко Михайло on 25.06.16.
//  Copyright © 2016 Карпенко Михайло. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import Photos


class CaptureViewController: UIViewController {
	
	@IBOutlet weak var camera: UIView!
	@IBOutlet weak var changeCameraButton: UIBarButtonItem!
	@IBOutlet weak var captureDevice: UIImageView!
	@IBOutlet weak var recordButton: UIButton!
	
	//camera values
	let captureSession = AVCaptureSession()
	var usingFrontCamera = true
	var frontCaptureDevice:AVCaptureDevice?
	var backCaptureDevice:AVCaptureDevice?
	var previewLayer:AVCaptureVideoPreviewLayer?
	var currentCamera = "front"
	
	//recordings video values
	var isVideoRecording = false
	var videoFileOutput = AVCaptureMovieFileOutput()
	
	//timer values
	var timer: NSTimer!
	var counter: Double!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Make navigation bar transparent
		let navigationBar:UINavigationBar! =  self.navigationController?.navigationBar
		navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
		navigationBar.shadowImage = UIImage()
		navigationBar.alpha = 0.0
		
		self.initCaptureDevices()
		self.beginCaptureSession()
		
		self.timer = NSTimer.init()
		self.counter = 0
	}
	
	func initCaptureDevices() {
		captureSession.sessionPreset = AVCaptureSessionPresetHigh
		let devices = AVCaptureDevice.devices()
		for device in devices {
			if (device.hasMediaType(AVMediaTypeVideo)) {
				if(device.position == AVCaptureDevicePosition.Front) {
					self.frontCaptureDevice = device as? AVCaptureDevice
					if self.frontCaptureDevice != nil {
						print("Front capture device found!")
					}
				}
				if(device.position == AVCaptureDevicePosition.Back) {
					self.backCaptureDevice = device as? AVCaptureDevice
					if self.backCaptureDevice != nil {
						print("Back capture device found!")
					}
				}
			}
		}
	}
	
	private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
		layer.videoOrientation = orientation
		self.previewLayer!.frame = self.view.bounds
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if let connection =  self.previewLayer?.connection  {
			let currentDevice: UIDevice = UIDevice.currentDevice()
			let orientation: UIDeviceOrientation = currentDevice.orientation
			let previewLayerConnection : AVCaptureConnection = connection
			
			if (previewLayerConnection.supportsVideoOrientation) {
			switch (orientation) {
				case .Portrait: updatePreviewLayer(previewLayerConnection, orientation: .Portrait)
					break
				case .LandscapeRight: updatePreviewLayer(previewLayerConnection, orientation: .LandscapeLeft)
					break
				case .LandscapeLeft: updatePreviewLayer(previewLayerConnection, orientation: .LandscapeRight)
					break
				case .PortraitUpsideDown: updatePreviewLayer(previewLayerConnection, orientation: .PortraitUpsideDown)
					break
				default: updatePreviewLayer(previewLayerConnection, orientation: .Portrait)
					break
				}
			}
		}
	}
	
	func beginCaptureSession() {
		do {
			self.captureSession.addInput(try AVCaptureDeviceInput(device: self.frontCaptureDevice))
		} catch _ {
			// Handle errors here...
		}
		
		self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		self.camera.layer.addSublayer(self.previewLayer!)
		
		// Blured background with rectangle layer mask inside
		let blurEffect = UIBlurEffect(style: .Dark)
		let blurredEffectView = UIVisualEffectView(effect: blurEffect)
		blurredEffectView.frame = self.view.bounds
		let maskLayer = CAShapeLayer()
		
		let path = UIBezierPath(rect: self.view.bounds)
		path.appendPath(UIBezierPath(rect: CGRectMake(self.view.bounds.midX/2, self.view.bounds.midY/1.5, self.view.bounds.midX*1.2, self.view.bounds.midX*1.2)))
		maskLayer.path = path.CGPath
		maskLayer.fillRule = kCAFillRuleEvenOdd
		blurredEffectView.layer.mask = maskLayer
		blurredEffectView.clipsToBounds = true
		self.camera.addSubview(blurredEffectView)
		
		self.captureSession.startRunning()
	}
	
	@IBAction func changeCamera(sender: AnyObject) {
		
		// Delete old input
		for input in self.captureSession.inputs {
			self.captureSession.removeInput(input as! AVCaptureInput)
		}
		
		// Add new input
		if (self.currentCamera=="front") {
			self.currentCamera="back"
			self.changeCameraButton.image = UIImage(named: "ic_camera_front_white")
			do {
				self.captureSession.addInput(try AVCaptureDeviceInput(device: self.backCaptureDevice))
			} catch _ {
				// Handnle errors here...
			}
			
			return
		}
		if (self.currentCamera=="back") {
			self.currentCamera="front"
			self.changeCameraButton.image = UIImage(named: "ic_camera_rear_white")
			do {
				self.captureSession.addInput(try AVCaptureDeviceInput(device: self.frontCaptureDevice))
			} catch _ {
				// Handle errors here...
			}
			
			return
		}
	}
	
	func updateCounter() {
		self.counter = self.counter!+0.01
		recordButton.setTitle(self.getNormalizedString(self.counter), forState: .Normal)
		if(Int(self.counter) % 2 != 1) {
			UIView.animateWithDuration(0.3, animations: {
				self.recordButton.titleLabel?.alpha = 1.0
				self.recordButton.imageView?.alpha = 0.0
			})
		} else {
			UIView.animateWithDuration(0.3, animations: {
				self.recordButton.titleLabel?.alpha = 1.0
				self.recordButton.imageView?.alpha = 1.0
			})
		}
	}
	
	func setPlayStopSystemItem(name: String) {
		if (name == "play") {
			recordButton.setTitle("Record", forState: .Normal)
			recordButton.tintColor = UIColor.redColor()
			return
		}
		if (name == "stop") {
			counter = 0.0
			recordButton.tintColor = UIColor.greenColor()
			return
		}
	}
	
	func getNormalizedString(counter: Double) -> String {
		let interval = NSTimeInterval.init(counter)
		return interval.hoursMinutesSeconds
	}
	
	@IBAction func record(sender: AnyObject) {
		if (self.timer?.valid==true){
			self.timer.invalidate()
			self.setPlayStopSystemItem("play")
			return
		}
		self.timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: #selector(CaptureViewController.updateCounter), userInfo: nil, repeats: true)
		self.setPlayStopSystemItem("stop")
		
		// Recording video
		if(self.isVideoRecording==false){
			self.isVideoRecording=true
			let videoDelegate = VideoDelegate()
			self.videoFileOutput = AVCaptureMovieFileOutput()
			self.captureSession.addOutput(self.videoFileOutput)
			let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
			let outputPath = "\(documentsPath)/Output.mov"
			let outputFileUrl = NSURL(fileURLWithPath: outputPath)
			self.videoFileOutput.startRecordingToOutputFileURL(outputFileUrl, recordingDelegate: videoDelegate)
			
			ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(outputFileUrl, completionBlock: nil)
			return
		}
		if(self.isVideoRecording==true){
			self.videoFileOutput.stopRecording()
			for output in self.captureSession.outputs {
				self.captureSession.removeOutput(output as! AVCaptureOutput)
			}
			self.isVideoRecording=false
			return
		}
	}
	
	
	
	// Only portrait
//	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
//		return UIInterfaceOrientationMask.Portrait
//	}
	
	
	
}

	//Only portrait
extension UINavigationController {
	public override func shouldAutorotate() -> Bool {
		return true
	}
	
	public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return (visibleViewController?.supportedInterfaceOrientations())!
	}
}
// Working with time representation
extension NSTimeInterval {
	
	var minuteSecondMS: String {
		return String(format:"%02d:%02d:%02d", self.minute, self.second, self.millisecond)
	}
	
	var hoursMinutesSeconds: String {
		return String(format:"%02d:%02d:%02d", self.hour, self.minute, self.second)
	}
	
	var hour: Int {
		return Int (self/3600)
	}
	
	var minute: Int {
		return Int(self/60.0 % 60)
	}
	var second: Int {
		return Int(self % 60)
	}
	var millisecond: Int {
		//return Int(self*1000 % 1000)
		return Int(self*1000 % 100)
	}
}

// Working wiht time representation
extension Int {
	var msToSeconds: Double {
		return Double(self) / 1000
	}
}

