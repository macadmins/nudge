//
//  BackgroundBlur.swift
//
//  Created by Bart Reardon on 23/2/2022.
//

import Foundation
import Cocoa

var loopedScreen = NSScreen()

class BlurWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.fullSizeContentView],  backing: .buffered, defer: true)
    }
}

class BlurWindowController: NSWindowController {
    convenience init() {
        self.init(windowNibName: "BlurWindow")
    }
    
    override func loadWindow() {
        window = BlurWindow(contentRect: NSMakeRect(0, 0, 0, 0), styleMask: [], backing: .buffered, defer: true)
        self.window?.contentViewController = BlurViewController()
        self.window?.setFrame((loopedScreen.frame), display: true)
        self.window?.collectionBehavior = [.canJoinAllSpaces]
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
        blurView.material = .fullScreenUI
        blurView.state = .active
        view.window?.contentView?.addSubview(blurView)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        view.window?.contentView?.removeFromSuperview()
    }
    
}
