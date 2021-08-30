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
    @ObservedObject var viewObserved: ViewState
    // Nudge UI
    var body: some View {
        HStack {
            // Left side of Nudge
            StandardModeLeftSide(viewObserved: viewObserved)
                .frame(width: 300)

            // Vertical Line
            VStack{
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 1)
            }
            .frame(height: 525)
            
            // Right side of Nudge
            StandardModeRightSide(viewObserved: viewObserved)
                .padding(.bottom, -60.0)
        }
        .frame(width: 900, height: 450)
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct StandardModePreviews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es"], id: \.self) { id in
                StandardMode(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            ZStack {
                StandardMode(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
#endif
