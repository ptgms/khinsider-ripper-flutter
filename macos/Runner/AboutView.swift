//
//  AboutViewController.swift
//  Runner
//
//  Created by ptgms on 06.07.22.
//

import Foundation
import Cocoa

class AboutView: NSPanel {
    @IBAction func sourceButtonPressed(_ sender: Any) {
        let url = URL(string: "https://github.com/ptgms/khinsider-ripper-flutter")!
        NSWorkspace.shared.open(url)
    }
    
}
