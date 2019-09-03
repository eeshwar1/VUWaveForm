//
//  Draw2dWaveform.swift
//  Beatmaker
//
//  Created by Miguel Saldana on 10/17/16.
//  Copyright © 2016 Miguel Saldana. All rights reserved.
//

import Foundation
import AppKit
import Accelerate
import AVFoundation

class WaveFormView2: NSView {
    
    var audioFileData: AudioFileData2?
    
    var samplesPerPoint: Int = 1000
    var waveAmplitude: CGFloat = 160.0
    var reflectionAmplitude: CGFloat = 100.0
    

    var graphColor : NSColor = NSColor.orange
    var reflectionColor : NSColor = NSColor.orange.blended(withFraction: 0.4, of: NSColor.yellow) ?? NSColor.white
    var backgroundColor: NSColor = NSColor.gray
    
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
        
        print("Creating URL Request...")
        let request = URLRequest(url: URL(string: url)!, cachePolicy: .reloadIgnoringLocalCacheData)
        print("Creating URL Session")
        let urlSession = URLSession.shared
        print("Create Data Task...")
        let task = urlSession.downloadTask(with: request) { (tempLocalURL, response, error) in
            
            if let tempLocalUrl = tempLocalURL, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Successfully downloaded. Status code: \(statusCode)")
                    self.loadFileFromURLPath(audioFileURL: tempLocalUrl.absoluteString)
                    
                }
                
                
            } else {
                print("Error took place while downloading a file. Error description: %@", error?.localizedDescription ?? "ERROR");
            }
            
            
        }
        
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
        
        self.audioFileData = AudioFileData2()
        
      
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
        
        print("DownSampled length: \(downSampledLength)")
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

struct AudioFileData2 {
    
    var arrayFloatValues:[Float] = []
    var points:[CGFloat] = []
    
}
