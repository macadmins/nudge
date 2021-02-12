//
//  ContentView.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import SwiftUI

// https://stackoverflow.com/a/66039864
// https://gist.github.com/steve228uk/c960b4880480c6ed186d

struct ContentView: View {
    @EnvironmentObject var manager: PolicyManager
    var body: some View {
        HostingWindowFinder {window in
            window?.standardWindowButton(.closeButton)?.isHidden = true //hides the red close button
            window?.standardWindowButton(.miniaturizeButton)?.isHidden = true //hides the yellow miniaturize button
            window?.standardWindowButton(.zoomButton)?.isHidden = true //this removes the green zoom button
            window?.center() // center
            window?.isMovable = false // not movable
            NSApp.activate(ignoringOtherApps: true) // bring to forefront upon launch
        }
        Nudge()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
    }
}

struct HostingWindowFinder: NSViewRepresentable {
    var callback: (NSWindow?) -> ()

    func makeNSView(context: Self.Context) -> NSView {
        let view = NSView()
        if randomDelay {
            let randomDelaySeconds = Int.random(in: 1...maxRandomDelayInSeconds)
            print("Delaying initial run by", String(randomDelaySeconds), "seconds...")
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(randomDelaySeconds)) { [weak view] in
                self.callback(view?.window)
            }
        } else {
            DispatchQueue.main.async { [weak view] in
                self.callback(view?.window)
            }
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
