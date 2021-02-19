//
//  StandardMode.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import Foundation
import SwiftUI

// Standard Mode
struct StandardMode: View {
    // Get the color scheme so we can dynamically change properties
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    @EnvironmentObject var manager: PolicyManager

    // State variables
    @State var daysRemaining = Utils().getNumberOfDaysBetween()
    @State var requireDualQuitButtons = Utils().requireDualQuitButtons()
    @State var pastRequiredInstallationDate = Utils().pastRequiredInstallationDate()
    @State var hasClickedSecondaryQuitButton = false
    @State var deferralCountUI = 0

    // Modal view for screenshot and device info
    @State var showSSDetail = false
    @State var showDeviceInfo = false

    // Get the screen frame
    var screen = NSScreen.main?.visibleFrame

    // Setup the main refresh timer that controls the child refresh logic
    let nudgeRefreshCycleTimer = Timer.publish(every: Double(nudgeRefreshCycle), on: .main, in: .common).autoconnect()

    // Nudge UI
    var body: some View {
        HStack(spacing: 0){
            // Life side of Nudge
            StandardModeLeftSide()

            // Vertical Line
            VStack{
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 1)
            }
            .frame(height: 525)
            
            // Right side of Nudge
            StandardModeRightSide()
            // https://www.hackingwithswift.com/books/ios-swiftui/running-code-when-our-app-launches
            .onAppear(perform: nudgeStartLogic)
        }
        .frame(width: 900, height: 450)
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct StandardModePreviews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es", "fr"], id: \.self) { id in
                StandardMode().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            StandardMode().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
                .preferredColorScheme(.dark)
        }
    }
}
#endif
