//
//  LeftSide.swift
//  Nudge
//
//  Created by Erik Gomez on 2/18/21.
//

import Foundation
import SwiftUI

// StandardModeLeftSide
struct StandardModeLeftSide: View {
    @EnvironmentObject var appState: AppState
    
    // Nudge UI
    var body: some View {
        // Left side of Nudge
        VStack {
            VStack(alignment: .center, spacing: 20) {
                // display the (?) info button
                AdditionalInfoButton()
                    .padding(3)
                
                // Company Logo
                CompanyLogo()
                
                // Horizontal line
                HStack{
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(height: 1)
                }
                .padding(.leading,contentWidthPadding)
                .padding(.trailing,contentWidthPadding)
                
                VStack(alignment: .center, spacing: 10) {
                    // Required OS Version
                    HStack{
                        Text("Required OS Version:".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                            .fontWeight(.bold)
                        Spacer()
                        Text(String(requiredMinimumOSVersion))
                            .foregroundColor(appState.colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
                            .fontWeight(.bold)
                    }
                    
                    // Current OS Version
                    HStack{
                        Text("Current OS Version:".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                        Spacer()
                        Text(currentOSVersion)
                            .foregroundColor(appState.colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
                    }
                    
                    // Days or Hours Remaining
                    HStack{
                        if (appState.daysRemaining > 0 && !Utils().demoModeEnabled()) || Utils().demoModeEnabled() {
                            Text("Days Remaining To Update:".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                            Spacer()
                            Text(String(appState.daysRemaining))
                                .foregroundColor(appState.colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
                        } else if appState.daysRemaining == 0 && !Utils().demoModeEnabled() {
                            Text("Hours Remaining To Update:".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                            Spacer()
                            Text(String(appState.hoursRemaining))
                                .foregroundColor(appState.differentiateWithoutColor ? .accessibleRed : .red)
                                .fontWeight(.bold)
                        } else {
                            Text("Days Remaining To Update:".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                            Spacer()
                            Text(String(appState.daysRemaining))
                                .foregroundColor(appState.differentiateWithoutColor ? .accessibleRed : .red)
                                .fontWeight(.bold)
                            
                        }
                    }
                    
                    // Deferred Count
                    // Show by default, allow to be hidden via preference
                    if showDeferralCount {
                        HStack{
                            Text("Deferred Count:".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                            Spacer()
                            Text(String(appState.userDeferrals))
                                .foregroundColor(appState.colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
                        }
                    }
                }
                .padding(.leading,contentWidthPadding)
                .padding(.trailing,contentWidthPadding)
            }
            
            // Force buttons to the bottom with a spacer
            Spacer()
        }
        .padding(.bottom, bottomPadding)
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct StandardModeLeftSide_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["en", "es"], id: \.self) { id in
            StandardModeLeftSide()
                .environmentObject(nudgePrimaryState)
                .environment(\.locale, .init(identifier: id))
                .previewDisplayName("LeftSide (\(id))")
        }
    }
}
#endif

