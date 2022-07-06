import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
    
    @IBOutlet var aboutWindow: NSWindow!
    
    
    @IBAction func showAbout(_ sender: NSMenuItem) {
        NSWindowController(window: aboutWindow).showWindow(self)
        
    }
    
    @IBAction func openIssue(_ sender: NSMenuItem) {
        let url = URL(string: "https://github.com/ptgms/khinsider-ripper-flutter/issues/new/choose")!
        NSWorkspace.shared.open(url)
    }
}
