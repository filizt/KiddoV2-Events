//
//  AlertViewController.swift
//  Kiddo Events
//
//  Created by Filiz Kurban on 3/13/17.
//  Copyright © 2017 Filiz Kurban. All rights reserved.
//

import Cocoa

class AlertViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    
    @IBAction func OKButton(_ sender: Any) {
        NSApplication.shared().terminate(self)
    }

}
