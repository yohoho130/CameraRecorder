//
//  VideoDelegate.swift
//  FutureRecords
//
//  Created by Карпенко Михайло on 26.06.16.
//  Copyright © 2016 Карпенко Михайло. All rights reserved.
//

import UIKit
import AVFoundation

class VideoDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
	
	func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
		print("Capture output : finish recording to \(outputFileURL)")
	}
	
	func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
		print("Capture output: started recording to \(fileURL)")
	}
}
