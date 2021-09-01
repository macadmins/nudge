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
    @ObservedObject var viewObserved: ViewState
    // Get the color scheme so we can dynamically change properties
    @Environment(\.colorScheme) var colorScheme
    
    let logoWidth: CGFloat = 200
    let logoHeight: CGFloat = 150
    
    let contentWidthPadding : CGFloat = 25
    let bottomPadding: CGFloat = 10
    
    // Nudge UI
    var body: some View {
        // Left side of Nudge
        VStack {
            VStack(alignment: .center, spacing: 20) {
                // display the (?) info button
                AdditionalInfoButton()
                
                // Company Logo
                CompanyLogo(width: logoWidth, height: logoHeight)
                
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
                        Text("Required OS Version:".localized(desiredLanguage: getDesiredLanguage()))
                            .fontWeight(.bold)
                        Spacer()
                        Text(String(requiredMinimumOSVersion))
                            .foregroundColor(.secondary)
                            .fontWeight(.bold)
                    }

                    // Current OS Version
                    HStack{
                        Text("Current OS Version:".localized(desiredLanguage: getDesiredLanguage()))
                        Spacer()
                        Text(currentOSVersion)
                            .foregroundColor(.secondary)
                    }

                    // Days Remaining
                    HStack{
                        Text("Days Remaining To Update:".localized(desiredLanguage: getDesiredLanguage()))
                        Spacer()
                        if viewObserved.daysRemaining <= 0 && !Utils().demoModeEnabled() {
                            Text(String(viewObserved.daysRemaining))
                                .foregroundColor(.red)
                                .fontWeight(.bold)
                        } else {
                            Text(String(viewObserved.daysRemaining))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Deferred Count
                    // Show by default, allow to be hidden via preference
                    if showDeferralCount {
                        HStack{
                            Text("Deferred Count:".localized(desiredLanguage: getDesiredLanguage()))
                            Spacer()
                            Text(String(viewObserved.userDeferrals))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.leading,contentWidthPadding)
                .padding(.trailing,contentWidthPadding)
            }

            // Force buttons to the bottom with a spacer
            Spacer()

            // More Info
            // informationButton
            InformationButton()
                .padding(.leading,contentWidthPadding)
                .padding(.trailing,contentWidthPadding)
        }
        .padding(.bottom, bottomPadding)
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct StandardModeLeftSide_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es"], id: \.self) { id in
                StandardModeLeftSide(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            ZStack {
                StandardModeLeftSide(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
#endif

