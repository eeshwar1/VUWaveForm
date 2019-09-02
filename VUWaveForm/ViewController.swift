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

    // MARK:- Outlets
    @IBOutlet weak var waveFormView1: NSView!
    @IBOutlet weak var waveFormView2: NSView!
    @IBOutlet weak var waveFormView3: NSView!
    @IBOutlet weak var waveFormView4: NSView!

    @IBOutlet weak var textfieldMultiplier: NSTextField!
    @IBOutlet weak var tableViewFileData: NSTableView!
    @IBOutlet weak var labelFileName: NSTextField!
    @IBOutlet weak var labelSampleRate: NSTextField!
    
    // MARK:- General Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        if let waveFormView1 = self.waveFormView1 as? WaveFormView {
            waveFormView1.loadFileFromBundle(audioFileName: "Sample1", fileExtension: "mp3")
            
        }

        
        if let waveFormView2 = self.waveFormView2 as? WaveFormView {
            waveFormView2.loadFileFromBundle(audioFileName: "sample2", fileExtension: "m4a")
            
        }
        
        if let waveFormView3 = self.waveFormView3 as? WaveFormView {
            waveFormView3.loadFileFromBundle(audioFileName: "piano", fileExtension: "caf")
            

        }
        
        if let waveFormView4 = self.waveFormView4 as? WaveFormView {
            print("Loading file from URL...")
            waveFormView4.downloadFileFromURL(url: "http://feeds.soundcloud.com/stream/673913966-thetalkshow-262-brent-simmons.mp3")
        }
        
     
        
        
        print("Loading url http://feeds.soundcloud.com/stream/673913966-thetalkshow-262-brent-simmons.mp3")
        // loadURLData(url: "http://feeds.soundcloud.com/stream/673913966-thetalkshow-262-brent-simmons.mp3")
        
        
 
       // print("Reading file \(String(describing: url))")
   
        // print("Initial point count: \(readFile.arrayFloatValues.count)")
        
       // labelFileName.stringValue = file.url.relativeString
       // labelSampleRate.stringValue = String(describing: file.fileFormat.sampleRate)
    
    }
    
    func loadURLFileIntoView(url: URL)
    {
        print("loading URL \(url.absoluteString) into View")
        
        if let waveFormView4 = self.waveFormView4 as? WaveFormView {
            print("Calling loadFileFromURLPath")
            waveFormView4.downloadFileFromURL(url: url.absoluteString)
        }
        
    }
    // MARK:- Actions
    
    @IBAction func displayGraph_clicked(_ sender: NSButton) {
        
        if let waveFormView = self.waveFormView1 as? WaveFormView {
            
            waveFormView.needsDisplay = true
        }
    }

   
    
}


