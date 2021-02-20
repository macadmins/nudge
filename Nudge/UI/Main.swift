//
//  Main.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    // Thanks you ftiff
    // Create an AppDelegate so the close button will terminate Nudge
    // Technically not needed because we are now hiding those buttons
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
    
    // Disable CMD+Q - Only exit if primaryQuitButton is clicked
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if shouldExit {
            return NSApplication.TerminateReply.terminateNow
        } else {
            return NSApplication.TerminateReply.terminateCancel
        }
    }
}

@main
struct Main: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let manager = try! PolicyManager() // TODO: handle errors
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(manager)
                .frame(width: 900, height: 450)
        }
        // Hide Title Bar
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
