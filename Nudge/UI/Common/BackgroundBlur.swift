//
//  BackgroundBlur.swift
//
//  Created by Bart Reardon on 23/2/2022.
//

import Cocoa
import Foundation

var loopedScreen = NSScreen()

class BackgroundBlurWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.fullSizeContentView], backing: .buffered, defer: flag)
    }
}

class BackgroundBlurWindowController: NSWindowController {
    override init(window: NSWindow?) {
        super.init(window: window)
        loadWindow()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadWindow() {
        let window = BackgroundBlurWindow(contentRect: NSRect.zero, styleMask: [], backing: .buffered, defer: true)
        window.contentViewController = BlurViewController()
        window.setFrame(loopedScreen.frame, display: true)
        window.collectionBehavior = [.canJoinAllSpaces]
        self.window = window
    }
}

class BlurViewController: NSViewController {
    private var blurView: NSVisualEffectView?
    
    override func loadView() {
        view = NSView()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        setupBlurView()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        blurView?.removeFromSuperview()
    }
    
    private func setupBlurView() {
        guard let contentView = view.window?.contentView else { return }
        
        view.window?.isOpaque = false
        view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)) - 1)
        
        let blurView = NSVisualEffectView(frame: contentView.bounds)
        blurView.blendingMode = .behindWindow
        blurView.material = .fullScreenUI
        blurView.state = .active
        contentView.addSubview(blurView)
        self.blurView = blurView
    }
}
