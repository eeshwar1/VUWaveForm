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

    @IBOutlet weak var labelStatus: NSTextField!
    
    // MARK:- General Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        
        if let waveFormView1 = self.waveFormView1 as? WaveFormView {
            waveFormView1.loadFileFromBundle(audioFileName: "sample2", fileExtension: "m4a")
            waveFormView1.mouseCallback = self.updateStatus
        }

        
    
    }
    
    // MARK:- Actions
    

    func updateStatus(message: String) {
        
        self.labelStatus.stringValue = message
        
    }

   
    
}


