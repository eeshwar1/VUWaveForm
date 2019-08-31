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

class WaveFormView: NSView {
    
    var multiplier: Float = 5.0 {
        didSet {
            
          if self.multiplier < 1.0 {
                self.multiplier = 1.0
                
            }
        }
    }
    
    var graphColor : NSColor = NSColor.orange
    var reflectionColor : NSColor = NSColor.orange.blended(withFraction: 0.4, of: NSColor.blue) ?? NSColor.white
    
    override func draw(_ rect: CGRect) {
        
        NSColor.black.setFill()
        rect.fill()
        let waveAmplitude: CGFloat = 160.0
        let reflectionAmplitude: CGFloat = 100.0
        
        self.convertToPoints()
        
        var f = 0
        
        print("Drawing the waveform...")
        
        let aPath = NSBezierPath()
        let aPath2 = NSBezierPath()
        
        aPath.lineWidth = 2.0
        aPath2.lineWidth = 2.0
        
        aPath.move(to: NSPoint(x:0.0 , y:rect.height/2 ))
        aPath2.move(to: NSPoint(x:0.0 , y:rect.height ))
        
        
        print("readFile Points: \(readFile.points)")
        
        for _ in readFile.points{
            //separation of points
            var x: CGFloat = 0.5 // was 2.5
            aPath.move(to: NSPoint(x:aPath.currentPoint.x + x , y:aPath.currentPoint.y ))
                
                //Y is the amplitude
            aPath.line(to: NSPoint(x: aPath.currentPoint.x, y: aPath.currentPoint.y + (readFile.points[f] * waveAmplitude) + 1.0))
            
                
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
        for _ in readFile.points{
            var x:CGFloat = 0.5 // 2.5
            aPath2.move(to: NSPoint(x:aPath2.currentPoint.x + x , y:aPath2.currentPoint.y ))
            
            //Y is the amplitude
            
            aPath2.line(to: NSPoint(x:aPath2.currentPoint.x  , y:aPath2.currentPoint.y - (readFile.points[f]) * reflectionAmplitude))
            
            
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
    
    func readArray( array:[Float]){
        readFile.arrayFloatValues = array
    }
    
    func convertToPoints() {
        
        var processingBuffer = [Float](repeating: 0.0,
                                       count: Int(readFile.arrayFloatValues.count))
        let sampleCount = vDSP_Length(readFile.arrayFloatValues.count)
        
        // print(sampleCount)
        
        vDSP_vabs(readFile.arrayFloatValues, 1, &processingBuffer, 1, sampleCount)
   
        print("Multiplier: \(self.multiplier)")
       
        
        let samplesPerPixel = Int(150 * multiplier)
        let filter = [Float](repeating: 1.0 / Float(samplesPerPixel),
                             count: Int(samplesPerPixel))
        let downSampledLength = Int(readFile.arrayFloatValues.count / samplesPerPixel)
        var downSampledData = [Float](repeating:0.0,
                                      count:downSampledLength)
        vDSP_desamp(processingBuffer,
                    vDSP_Stride(samplesPerPixel),
                    filter, &downSampledData,
                    vDSP_Length(downSampledLength),
                    vDSP_Length(samplesPerPixel))
        
        // convert [Float] to [CGFloat] array
        readFile.points = downSampledData.map{CGFloat($0)}
        
        
    }
    
}

struct readFile {
    static var arrayFloatValues:[Float] = []
    static var points:[CGFloat] = []
    
}
