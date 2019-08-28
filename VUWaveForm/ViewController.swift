//
//  ViewController.swift
//  VUWaveForm
//
//  Created by Venky Venkatakrishnan on 8/27/19.
//  Copyright © 2019 Venky UL. All rights reserved.
//

import Cocoa
import AVFoundation

class ViewController: NSViewController {

    @IBOutlet weak var waveFormView: NSView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
       //  let url = Bundle.main.url(forResource: "sample2", withExtension: "m4a")
        
        let url = Bundle.main.url(forResource: "Sample1", withExtension: "mp3")
        let file = try! AVAudioFile(forReading: url!)
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false) else {
            print(" returning...")
            return  }
        
        print(file.fileFormat.channelCount)
        
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(file.length))
        
        do {
            try file.read(into: buf!)
        }
        catch {
            print("Unable to read file: \(file)")
        }
        
        readFile.arrayFloatValues = Array(UnsafeBufferPointer(start: buf?.floatChannelData?[0], count:Int(buf!.frameLength)))
        
        //self.view.addSubview(waveFormView)
        // self.waveFormView.needsDisplay = true
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

