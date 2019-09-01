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
    @IBOutlet weak var textfieldMultiplier: NSTextField!
    @IBOutlet weak var tableViewFileData: NSTableView!
    
    @IBOutlet weak var labelFileName: NSTextField!
    @IBOutlet weak var labelSampleRate: NSTextField!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        if let waveFormView = self.waveFormView as? WaveFormView {
            waveFormView.loadFileFromBundle(audioFileName: "Sample1", fileExtension: "mp3")
            
        }
    
     
        // print("Reading file \(String(describing: url))")
   
        // print("Initial point count: \(readFile.arrayFloatValues.count)")
        
       // labelFileName.stringValue = file.url.relativeString
       //  labelSampleRate.stringValue = String(describing: file.fileFormat.sampleRate)
    
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // MARK:- Actions
    
    @IBAction func displayGraph_clicked(_ sender: NSButton) {
        
        if let waveFormView = self.waveFormView as? WaveFormView {
            
            // waveFormView.multiplier = textfieldMultiplier.floatValue
            waveFormView.needsDisplay = true
        }
    }


}

