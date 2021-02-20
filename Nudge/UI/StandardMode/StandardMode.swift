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

    // Get the screen frame
    var screen = NSScreen.main?.visibleFrame

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
        }
        .frame(width: 900, height: 450)
        // https://www.hackingwithswift.com/books/ios-swiftui/running-code-when-our-app-launches
        .onAppear(perform: nudgeStartLogic)
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
