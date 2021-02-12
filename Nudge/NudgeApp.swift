//
//  NudgeApp.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import SwiftUI

// Thanks you ftiff
// Create an AppDelegate so the close button will terminate Nudge
// Technically not needed because we are now hiding those buttons

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct NudgeApp: App {
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
