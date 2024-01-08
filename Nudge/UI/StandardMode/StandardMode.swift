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
                .frame(width: UIConstants.leftSideWidth)

            Divider()
                .padding(.vertical, UIConstants.contentWidthPadding)

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
        .padding(.bottom, UIConstants.bottomPadding)
        .padding(.leading, UIConstants.contentWidthPadding)
        .padding(.trailing, UIConstants.contentWidthPadding)
    }
}

#if DEBUG
#Preview {
    ForEach(["en", "es"], id: \.self) { id in
        StandardMode()
            .environmentObject(nudgePrimaryState)
            .previewLayout(.fixed(width: uiConstants.declaredWindowWidth, height: uiConstants.declaredWindowHeight))
            .environment(\.locale, .init(identifier: id))
            .previewDisplayName("StandardMode (\(id))")
    }
}
#endif
