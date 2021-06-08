//
//  Main.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import SwiftUI

// Create an AppDelegate so that we can more finely control how Nudge operates
class AppDelegate: NSObject, NSApplicationDelegate {
    // This allows Nudge to terminate if all of the windows have been closed. It was needed when the close button was visible, but less needed now.
    // However if someone does close all the windows, we still want this.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Listen for keyboard events
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            if self.detectBannedShortcutKeys(with: $0) {
                return nil
            } else {
                return $0
            }
        }
    }
    
    func detectBannedShortcutKeys(with event: NSEvent) -> Bool {
        // Only detect shortcut keys if Nudge is active - adapted from https://stackoverflow.com/questions/32446978/swift-capture-keydown-from-nsviewcontroller/40465919
        if NSApplication.shared.isActive {
            switch event.modifierFlags.intersection(.deviceIndependentFlagsMask) {
                // Disable CMD + W - closes the Nudge window and breaks it
                case [.command] where event.characters == "w":
                    let msg = "Nudge detected an attempt to close the application via CMD + W shortcut key."
                    uiLog.warning("\(msg, privacy: .public)")
                    return true
                // Disable CMD + Q -  fully closes Nudge
                case [.command] where event.characters == "q":
                    let msg = "Nudge detected an attempt to close the application via CMD + Q shortcut key."
                    uiLog.warning("\(msg, privacy: .public)")
                    return true
                // Don't care about any other shortcut keys
                default:
                    return false
            }
        }
        return false
    }
    
    // Only exit if primaryQuitButton is clicked
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if shouldExit {
            return NSApplication.TerminateReply.terminateNow
        } else {
            let msg = "Nudge detected an attempt to close the application."
            uiLog.warning("\(msg, privacy: .public)")
            return NSApplication.TerminateReply.terminateCancel
        }
    }

    func runSoftwareUpdate() {
        if Utils().unsafeSoftwareUpdate() {
            // Temporary workaround for Big Sur bug
            let msg = "Due to a bug in Big Sur 11.3 and lower, Nudge cannot reliably use /usr/sbin/softwareupdate to download updates. See https://openradar.appspot.com/radar?id=4987491098558464 for more information regarding this issue."
            softwareupdateDownloadLog.warning("\(msg, privacy: .public)")
        } else {
            if asyncronousSoftwareUpdate {
                DispatchQueue(label: "nudge-su", attributes: .concurrent).asyncAfter(deadline: .now(), execute: {
                    SoftwareUpdate().Download()
                })
            } else {
                SoftwareUpdate().Download()
            }
        }
    }

    // Random Delay logic
    func applicationWillFinishLaunching(_ notification: Notification) {
        if randomDelay {
            let randomDelaySeconds = Int.random(in: 1...maxRandomDelayInSeconds)
            uiLog.notice("Delaying initial run (in seconds) by: \(String(randomDelaySeconds), privacy: .public)")
            sleep(UInt32(randomDelaySeconds))
        }
        self.runSoftwareUpdate()
    }
}

@main
struct Main: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let manager = try! PolicyManager() // TODO: handle errors
    var body: some Scene {
        #if DEBUG
        WindowGroup {
            VSplitView {
                ContentView(simpleModePreview: false).environmentObject(manager)
                    .onAppear(perform: nudgeStartLogic)
                    .frame(width: 900, height: 450)
                ContentView(simpleModePreview: true).environmentObject(manager)
                    .onAppear(perform: nudgeStartLogic)
                    .frame(width: 900, height: 450)
            }
            .frame(height: 900)
        }
        // Hide Title Bar
        .windowStyle(HiddenTitleBarWindowStyle())
        #endif

        WindowGroup {
            ContentView(simpleModePreview: false).environmentObject(manager)
                .onAppear(perform: nudgeStartLogic)
                .frame(width: 900, height: 450)
        }
        // Hide Title Bar
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
