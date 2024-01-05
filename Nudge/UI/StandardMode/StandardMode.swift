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
            standardModeContent
            bottomButtons
        }
    }
    
    private var standardModeContent: some View {
        HStack {
            StandardModeLeftSide()
                .frame(width: leftSideWidth)
            
            Divider()
                .padding(.vertical, contentWidthPadding)

            StandardModeRightSide()
        }
    }
    
    private var bottomButtons: some View {
        HStack {
            InformationButton()
            
            if appState.allowButtons || CommandLineUtilities().demoModeEnabled() {
                QuitButtons()
            }
        }
        .padding(.bottom, bottomPadding)
        .padding(.leading, contentWidthPadding)
        .padding(.trailing, contentWidthPadding)
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
