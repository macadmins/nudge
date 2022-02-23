//
//  BackgroundBlur.swift
//
//  Created by Bart Reardon on 23/2/2022.
//

import Foundation
import Cocoa

class BlurWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.fullSizeContentView],  backing: .buffered, defer: true)
     }
}

class BlurWindowController: NSWindowController {
    
    convenience init() {
        self.init(windowNibName: "")
    }
        
    override func loadWindow() {
        window = BlurWindow(contentRect: NSMakeRect(0, 0, 100, 100), styleMask: [], backing: .buffered, defer: true)
        self.window?.contentViewController = BlurViewController()
        self.window?.standardWindowButton(.closeButton)?.isHidden = true //hides the red close button
        self.window?.standardWindowButton(.miniaturizeButton)?.isHidden = true //hides the yellow miniaturize button
        self.window?.standardWindowButton(.zoomButton)?.isHidden = true //this removes the green zoom button
        self.window?.setFrame((NSScreen.main?.frame)!, display: true)
        self.window?.collectionBehavior = NSWindow.CollectionBehavior.canJoinAllSpaces
    }
}

class BlurViewController: NSViewController {
    
    init() {
         super.init(nibName: nil, bundle: nil)
     }
     
    required init?(coder: NSCoder) {
         fatalError()
     }
    
    override func loadView() {
        super.viewDidLoad()
        self.view = NSView()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.isOpaque = false
        view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow) - 1 ))
        
        let blurView = NSVisualEffectView(frame: view.bounds)
        blurView.blendingMode = .behindWindow
        blurView.material = .hudWindow
        blurView.state = .active
        view.window?.contentView?.addSubview(blurView)
    }
    
}
