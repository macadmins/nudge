//
//  StandardMode.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import Foundation
import SwiftUI

struct StandardMode: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack {
            HStack {
                StandardModeLeftSide()
                    .frame(width: leftSideWidth)
                
                // Vertical Line
                VStack{
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 1)
                }

                StandardModeRightSide()
            }
            // Bottom buttons
            HStack {
                InformationButton()
                
                if appState.allowButtons || Utils().demoModeEnabled() {
                    QuitButtons()
                }
            }
            .padding(.bottom, bottomPadding)
            .padding(.leading, contentWidthPadding)
            .padding(.trailing, contentWidthPadding)
        }
    }
}

#if DEBUG
#Preview {
    ForEach(["en", "es"], id: \.self) { id in
        StandardMode()
            .environmentObject(nudgePrimaryState)
            .previewLayout(.fixed(width: declaredWindowWidth, height: declaredWindowHeight))
            .environment(\.locale, .init(identifier: id))
            .previewDisplayName("StandardMode (\(id))")
    }
}
#endif
