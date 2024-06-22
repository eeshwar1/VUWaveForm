//
//  WaveFormView.swift
//  VUWaveForm
//
//  Created by Venky Venkatakrishnan on 8/27/19.
//  Copyright © 2019 Venky UL. All rights reserved.
//
import Foundation
import AppKit
import AVFoundation
import Accelerate

struct AudioFileData {
    
    var arrayFloatValues:[Float] = []
    
    var lengthInTime: Double = 0.0
    
    init(arrayFloatValues: [Float], lengthInTime: Double) {
        self.arrayFloatValues = arrayFloatValues
        self.lengthInTime = lengthInTime
    }
    
    func getPoints(samplesPerPoint: Int) -> [CGFloat] {
        
        
        var processingBuffer = [Float](repeating: 0.0,
                                       count: Int(arrayFloatValues.count))
        let sampleCount = vDSP_Length(arrayFloatValues.count)
        
        // print(sampleCount)
        
        vDSP_vabs(arrayFloatValues, 1, &processingBuffer, 1, sampleCount)
        
        let filter = [Float](repeating: 1.0 / Float(samplesPerPoint),
                             count: Int(samplesPerPoint))
        let downSampledLength = Int(arrayFloatValues.count / samplesPerPoint)
        
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
}


class WaveFormView: NSView {
    
    var mouseCallback: ((String) -> ())?
    
    var audioFileData: AudioFileData?
    
    var points: [CGFloat] = []
    var pointsLocations: [CGFloat] = []
    
    var samplesPerPoint: Int = 1000
    var waveAmplitude: CGFloat = 50.0
    var reflectionAmplitude: CGFloat = 50.0
    
    
    var graphColor : NSColor = NSColor.orange
    var reflectionColor : NSColor = NSColor.orange.blended(withFraction: 0.4, of: NSColor.yellow) ?? NSColor.white
    var backgroundColor: NSColor = NSColor.white
    
    var mouseLayer: CALayer = CALayer()
    
    var mouseLocation: NSPoint = NSPoint.zero
    
    let numberFormatter = NumberFormatter()
    
    override init(frame frameRect: NSRect) {
        
        super.init(frame: frameRect)
        commonInit()
        
    }
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        
        // mouseLayer.frame = self.frame
        
        self.wantsLayer = true
        self.layer?.borderColor = NSColor.black.cgColor
        self.layer?.borderWidth = 2.0
        self.clipsToBounds = true
        
        mouseLayer.borderColor = NSColor.green.cgColor
        mouseLayer.borderWidth = 2.0
        
        self.layer?.addSublayer(mouseLayer)
        
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
    }
    
    func loadFileFromBundle(audioFileName: String, fileExtension: String) {
        
        guard let url  = Bundle.main.url(forResource: audioFileName, withExtension: fileExtension) else {
            
            print("The file does not exist")
            return
            
        }
        
        do
        {
            let file = try AVAudioFile(forReading: url)
            loadAudioFileData(file: file)
            
        }
        catch {
            print("Error reading Audio file data '\(audioFileName).\(fileExtension)'")
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
            print("Returning...")
            return  }
        
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(file.length))
        
        do {
            try file.read(into: buf!)
        }
        catch {
            print("Unable to read file: \(file)")
        }
        
        let arrayFloatValues = Array(UnsafeBufferPointer(start: buf?.floatChannelData?[0], count:Int(buf!.frameLength)))
        
        
        let lengthInTime = Double(arrayFloatValues.count)/(file.fileFormat.sampleRate)
        
        self.audioFileData = AudioFileData(arrayFloatValues: arrayFloatValues, lengthInTime: lengthInTime)
        
    }
    
    
    
    override func draw(_ rect: CGRect) {
        
        drawCursor(location: self.mouseLocation, isCross: false)
        drawWaveForm()
        
    }
    
    fileprivate func drawWaveForm() {
        
        guard let fileData = self.audioFileData else
        {
            print("No data available to draw")
            return
        }
        
        self.backgroundColor.setFill()
        self.bounds.fill()
        
        
        let frameRect = self.frame
        
        calculateSamplesPerPixel()
        
        self.points = fileData.getPoints(samplesPerPoint: self.samplesPerPoint)
        calculateAmplitude(fileData: self.points)
        
        let wavePath = NSBezierPath()
        let reflectionPath = NSBezierPath()
        
        wavePath.lineWidth = 2.0
        reflectionPath.lineWidth = 2.0
        
        wavePath.move(to: NSPoint(x: 0.0 , y:frameRect.height/2 ))
        
        reflectionPath.move(to: NSPoint(x:0.0 , y:frameRect.height/2 ))
        
        let separation: CGFloat = 1.0
        
        for point in points {
            
            wavePath.move(to: NSPoint(x:wavePath.currentPoint.x + separation, y:wavePath.currentPoint.y ))
            
            // Y is the amplitude
            wavePath.line(to: NSPoint(x: wavePath.currentPoint.x, y: wavePath.currentPoint.y + (point * waveAmplitude) + 1.0))
            
            wavePath.close()
            
            //Reflection of the waveform
            reflectionPath.move(to: NSPoint(x:reflectionPath.currentPoint.x + separation , y:reflectionPath.currentPoint.y ))
            
            //Y is the amplitude
            
            reflectionPath.line(to: NSPoint(x: reflectionPath.currentPoint.x , y: reflectionPath.currentPoint.y - (point * reflectionAmplitude)))
            
            reflectionPath.close()
            
            
        }
        
        // If you want to stroke it with a Orange color
        self.graphColor.set()
        wavePath.stroke()
        // If you want to fill it as well
        wavePath.fill()
        
        self.reflectionColor.set()
        reflectionPath.stroke()
        // If you want to fill it as well
        reflectionPath.fill()
    }
    
    func drawCursor(location: NSPoint, isCross: Bool) {
        
        
        self.mouseLayer.sublayers?.removeAll()
        
        let line = CAShapeLayer()
        let crossPath = NSBezierPath()
        crossPath.move(to: CGPoint(x: location.x, y: self.bounds.minY))
        crossPath.line(to: CGPoint(x: location.x, y: self.bounds.maxY))
        
        if isCross {
            crossPath.move(to: CGPoint(x: self.bounds.minX, y: location.y))
            crossPath.line(to: CGPoint(x: self.bounds.maxX, y: location.y))
        }
        
        line.path = crossPath.cgPath
        line.fillColor = nil
        line.opacity = 2.0
        line.strokeColor = NSColor.black.cgColor
        line.lineDashPattern = .init(repeating: 2, count: 2)
        mouseLayer.addSublayer(line)
        
        
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
        
        
    }
    
    func calculateAmplitude(fileData: [CGFloat])
    {
        
        var maxAmplitude: CGFloat = 0.0
        for point in fileData {
            
            maxAmplitude = maxAmplitude < point ? point : maxAmplitude
            
        }
        
        let bufferedAmplitude = 1.1 * maxAmplitude
        let viewHeight = self.frame.height
        
        
        
        let amplitude = (viewHeight/2)/bufferedAmplitude
        self.waveAmplitude = amplitude
        self.reflectionAmplitude = 0.8 * amplitude
        
        
    }
    
    override func mouseMoved(with event: NSEvent) {
        
        let eventLocation = self.convert(event.locationInWindow, from: nil)
        
        let pointOffset = Int(eventLocation.x)
        
        self.mouseLocation = eventLocation
        
        
        self.needsDisplay = true
        
        if let callback = self.mouseCallback, points.count > 0  {
            
            var statusMessage = "Value at offset \(pointOffset)"
            
            let value = points[pointOffset] * waveAmplitude
            let stringValue = numberFormatter.string(from: value as NSNumber) ?? "Invalid"
            statusMessage += " is \(stringValue)"
            callback(statusMessage)
            
            
        }
    }
    
    override func updateTrackingAreas() {
        
        super.updateTrackingAreas()
        
        trackingAreas.forEach({ removeTrackingArea($0) })
        
        addTrackingArea(NSTrackingArea(rect: self.bounds,
                                       options: [.mouseMoved,
                                                 .mouseEnteredAndExited,
                                                 .activeAlways],
                                       owner: self))
    }
    
    
}


extension NSBezierPath {
    
    public var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0 ..< elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            case .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[2], control: points[0])
            @unknown default:
                continue
            }
        }
        
        return path
    }
}
