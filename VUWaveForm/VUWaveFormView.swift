//
//  VUWaveFormView.swift
//  VUWaveForm
//
//  Created by Venky Venkatakrishnan on 8/27/19.
//  Copyright © 2019 Venky UL. All rights reserved.
//

import Foundation
import AppKit
import Accelerate
import AVFoundation

class VUWaveFormView: NSView {
    
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var statusLabel: NSTextField!
    
    var audioFileData: AudioFileData?
    
    var samplesPerPoint: Int = 1000
    var waveAmplitude: CGFloat = 160.0
    var reflectionAmplitude: CGFloat = 100.0
    

    var graphColor : NSColor = NSColor.orange
    var reflectionColor : NSColor = NSColor.orange.blended(withFraction: 0.4, of: NSColor.yellow) ?? NSColor.white
    var backgroundColor: NSColor = NSColor.gray
    
    required init?(coder decoder: NSCoder) {
        
        super.init(coder: decoder)
        
        /// Extract our name string from the multi-level class name. We need it to reference the NIB name
        /// This is just Best Practice. The NIB may be named anything you like but makes sense to be named
        /// the same as the class that drives it.
        
        let myName = type(of: self).className().components(separatedBy: ".").last!
        
        /// Get our NIB. This should never fail but it always pays to be careful
        /// In this case it gets the main Bundle but if this code is in a Framework then it might be another one,
        /// that's why we use that form of Bundle call
        
        if let nib = NSNib.init(nibNamed: myName, bundle: Bundle(for: type(of: self)))
        {
            
            /// You must instantiate a new view from the NIB attached to you as the owner,
            /// this will replace the one originally built at app start-up
            nib.instantiate(withOwner: self, topLevelObjects: nil)
            
            /// Now create a new array of constraints by copying the old ones.
            /// We replace ourself as either the first or second item as appropriate in place of topView.
            /// We grab these now to apply after we add our sub-views
            
            var newConstraints: [NSLayoutConstraint] = []
            
            for oldConstraint in contentView.constraints {
                let firstItem = oldConstraint.firstItem === contentView ? self: oldConstraint.firstItem!
                let secondItem = oldConstraint.secondItem === contentView ? self: oldConstraint.secondItem
                newConstraints.append(NSLayoutConstraint(item: firstItem, attribute: oldConstraint.firstAttribute, relatedBy: oldConstraint.relation, toItem: secondItem, attribute: oldConstraint.secondAttribute, multiplier: oldConstraint.multiplier, constant: oldConstraint.constant))
            }
            for newView in contentView.subviews {
                self.addSubview(newView)
            }
            
            self.addConstraints(newConstraints)
        }
        
        
        
    }
    
    func loadFileFromBundle(audioFileName: String, fileExtension: String) {
        
        if let url = Bundle.main.url(forResource: audioFileName, withExtension: fileExtension) {
            
            do
            {
                let file = try AVAudioFile(forReading: url)
                loadAudioFileData(file: file)

            }
            catch {
                print("Error reading Audio file data '\(audioFileName).\(fileExtension)'")
            }
        }
        else {
            print("Error loading file '\(audioFileName).\(fileExtension)'")
        }
        
      
    }
    
    
    func loadFileFromURLPath(audioFileURL: String) {
        
        print("loadFileFromURLPath: \(audioFileURL)")
        
   
     
        if let url = URL(string: audioFileURL) {
            do
            {
                
                let file = try AVAudioFile(forReading: url)
                loadAudioFileData(file: file)
                
                OperationQueue.main.addOperation( {
                    
                    self.statusLabel.isHidden = true
                    self.needsDisplay = true
                    
                })
                
            }
            catch {
                print("Error reading Audio file data '\(audioFileURL)'")
            }
        }
        else {
            print("Error loading file '\(audioFileURL)'")
        }
        
        
    }
    
    func downloadFileFromURL(url: String)
    {
        
        // let documentsUrl:URL =  (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL?)!
        //  let destinationFileUrl = documentsUrl.appendingPathComponent("downloadedFile.mp3")
        
        OperationQueue.main.addOperation({
            
            self.statusLabel.isHidden = false
            self.statusLabel.stringValue = "Loading audio file..."
            
        })
        
        print("Creating URL Request...")
        let request = URLRequest(url: URL(string: url)!, cachePolicy: .reloadRevalidatingCacheData)
        print("Creating URL Session")
        let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        
        print("Create Data Task...")
        let task = urlSession.downloadTask(with: request)
     
        task.resume()
        
    }
    private func loadAudioFileData(file: AVAudioFile) {
        
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false) else {
            print(" returning...")
            return  }
        
        // print("Number of Channels: \(file.fileFormat.channelCount)")
        
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(file.length))
        
        do {
            try file.read(into: buf!)
        }
        catch {
            print("Unable to read file: \(file)")
        }
        
        self.audioFileData = AudioFileData()
        
      
        audioFileData!.arrayFloatValues = Array(UnsafeBufferPointer(start: buf?.floatChannelData?[0], count:Int(buf!.frameLength)))

        
    }
    
    override func draw(_ rect: CGRect) {
        
        self.backgroundColor.setFill()
        rect.fill()
        
        guard var fileData = self.audioFileData else
        {
            print("No data available to draw")
            return
        }
       
        
        calculateSamplesPerPixel()
        
        fileData.points = convertToPoints()
        self.audioFileData = fileData
       
        calculateAmplitude(fileData: fileData.points)
        
        // print("fileData Points Count: \(fileData.points.count)")
        
        // print("fileData Points data: \(fileData.points)")
        
        
        var f = 0
        
        print("Drawing the waveform...")
        
        let aPath = NSBezierPath()
        let aPath2 = NSBezierPath()
        
        aPath.lineWidth = 2.0
        aPath2.lineWidth = 2.0
        
        aPath.move(to: NSPoint(x:0.0 , y:rect.height/2 ))
        aPath2.move(to: NSPoint(x:0.0 , y:rect.height ))
        
        
      // print("self.audioFileData Points: \(self.audioFileData.points)")
        
        
        for _ in fileData.points {
            
            //separation of points
            
            var x: CGFloat = 1.0 // was 2.5
            aPath.move(to: NSPoint(x:aPath.currentPoint.x + x , y:aPath.currentPoint.y ))
                
                //Y is the amplitude
            aPath.line(to: NSPoint(x: aPath.currentPoint.x, y: aPath.currentPoint.y + (fileData.points[f] * waveAmplitude) + 1.0))
                
            aPath.close()
        
            x += 1
            f += 1

        }
       
        //If you want to stroke it with a Orange color
        self.graphColor.set()
        aPath.stroke()
        //If you want to fill it as well
        aPath.fill()
        
        
        f = 0
        aPath2.move(to: NSPoint(x:0.0 , y:rect.height/2 ))
        
        //Reflection of waveform
        for _ in fileData.points {
            var x:CGFloat = 1.0 // 2.5
            aPath2.move(to: NSPoint(x:aPath2.currentPoint.x + x , y:aPath2.currentPoint.y ))
            
            //Y is the amplitude
            
            aPath2.line(to: NSPoint(x:aPath2.currentPoint.x  , y:aPath2.currentPoint.y - (fileData.points[f]) * reflectionAmplitude))
            
            
            // aPath.close()
            aPath2.close()
            
            //print(aPath.currentPoint.x)
            x += 1
            f += 1
        }
        
        self.reflectionColor.set()
        aPath2.stroke()

        //If you want to fill it as wel
        aPath2.fill()
        
    }
    
    private func calculateSamplesPerPixel()    {
        
        guard let fileData = self.audioFileData else
        {
            print("No data available to calculate Samples per Pixel")
            return
        }
        
        let viewWidth = Float(self.frame.width)
        let inputSamplesCount: Float =  Float(fileData.arrayFloatValues.count)
        
        self.samplesPerPoint = Int((inputSamplesCount)/viewWidth)
        print("Width of View: \(viewWidth)")
        print("Calculated Samples per Point: \(self.samplesPerPoint)")
    }
    func readArray( array:[Float]){
        audioFileData!.arrayFloatValues = array
    }
    
    func convertToPoints() -> [CGFloat] {
        
        guard let fileData = self.audioFileData else
        {
            print("No data available to convert")
            return []
        }
        var processingBuffer = [Float](repeating: 0.0,
                                       count: Int(fileData.arrayFloatValues.count))
        let sampleCount = vDSP_Length(fileData.arrayFloatValues.count)
        
        // print(sampleCount)
        
        vDSP_vabs(fileData.arrayFloatValues, 1, &processingBuffer, 1, sampleCount)
       
        let filter = [Float](repeating: 1.0 / Float(self.samplesPerPoint),
                             count: Int(self.samplesPerPoint))
        let downSampledLength = Int(self.audioFileData!.arrayFloatValues.count / self.samplesPerPoint)
        
        print("Down Sampled length: \(downSampledLength)")
        var downSampledData = [Float](repeating:0.0,
                                      count:downSampledLength)
        vDSP_desamp(processingBuffer,
                    vDSP_Stride(samplesPerPoint),
                    filter, &downSampledData,
                    vDSP_Length(downSampledLength),
                    vDSP_Length(samplesPerPoint))
        
        // convert [Float] to [CGFloat] array
        let pointsData = downSampledData.map{CGFloat($0)}
        
        return pointsData
    }
    
    func calculateAmplitude(fileData: [CGFloat])
    {
        
        var maxAmplitude: CGFloat = 0.0
        for point in fileData {
            
            maxAmplitude = maxAmplitude < point ? point : maxAmplitude
            
        }
        
        let bufferedAmplitude = 1.1 * maxAmplitude
        let viewHeight = self.frame.height
        
        print("View Height: \(viewHeight)")
        print("Buffered Amplitude: \(bufferedAmplitude)")
        
        let amplitude = (viewHeight/2)/bufferedAmplitude
        self.waveAmplitude = amplitude
        self.reflectionAmplitude = 0.8 * amplitude
        
        print("Wave Amplitude: \(self.waveAmplitude)")
    }
    
}

// MARK:- URL Session Download Delegate
extension VUWaveFormView: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        
        OperationQueue.main.addOperation({
            
            self.statusLabel.isHidden = false
            self.statusLabel.stringValue = "Processing file..."
            
        })
        self.loadFileFromURLPath(audioFileURL: location.absoluteString)
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
      /*  guard
            (downloadTask.originalRequest?.url) != nil
            // let download = downloadService.activeDownloads[url]
            else {
                return
                
        }*/
        // 2
        // let downloadProgress = (Float(totalBytesWritten) * 100) / Float(totalBytesExpectedToWrite)
        
        let bytesDownloaded =    ByteCountFormatter.string(fromByteCount: totalBytesWritten,                                                           countStyle: .file)
        // 3
        let totalSize =
            ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite,
                                      countStyle: .file)
        // 4
        
        OperationQueue.main.addOperation({
            
            self.statusLabel.isHidden = false
            self.statusLabel.stringValue = "\(bytesDownloaded) of \(totalSize)"
            // self.needsDisplay = true
            
        })
            
        
    }
}
