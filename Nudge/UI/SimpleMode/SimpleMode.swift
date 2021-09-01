//
//  SimpleMode.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import Foundation
import SwiftUI

// SimpleMode
struct SimpleMode: View {
    @ObservedObject var viewObserved: ViewState
    // Get the color scheme so we can dynamically change properties
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
        
    let bottomPadding: CGFloat = 10
    let contentWidthPadding: CGFloat = 25
    
    let logoWidth: CGFloat = 200
    let logoHeight: CGFloat = 150
    
    // Nudge UI
    var body: some View {
        VStack {
            // display the (?) info button
            AdditionalInfoButton()

            VStack(alignment: .center, spacing: 10) {
                Spacer()
                // Company Logo
                CompanyLogo(width: logoWidth, height: logoHeight)
                Spacer()

                // mainHeader
                HStack {
                    Text(getMainHeader())
                        .font(.title)
                        .fontWeight(.bold)
                }
 
                // Days Remaining
                HStack(spacing: 3.5) {
                    Text("Days Remaining To Update:".localized(desiredLanguage: getDesiredLanguage()))
                        .font(.title2)
                    if viewObserved.daysRemaining <= 0 && !Utils().demoModeEnabled() {
                        Text(String(viewObserved.daysRemaining))
                            .foregroundColor(.red)
                            .font(.title2)
                            .fontWeight(.bold)
                    } else {
                        Text(String(viewObserved.daysRemaining))
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }

                // Deferral Count
                if showDeferralCount {
                    HStack{
                        Text("Deferred Count:".localized(desiredLanguage: getDesiredLanguage()))
                            .font(.title2)
                        Text(String(viewObserved.userDeferrals))
                            .foregroundColor(.secondary)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                } else {
                    HStack{
                        Text("Deferred Count:".localized(desiredLanguage: getDesiredLanguage()))
                            .font(.title2)
                        Text(String(viewObserved.userDeferrals))
                            .foregroundColor(.secondary)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .hidden()
                }
                Spacer()

                // actionButton
                Button(action: {
                    Utils().updateDevice()
                }) {
                    Text(actionButtonText)
                        .frame(minWidth: 120)
                }
                .keyboardShortcut(.defaultAction)
                Spacer()
            }
            .frame(alignment: .center)

            // Bottom buttons
            HStack {
                // informationButton
                InformationButton()
                
                if viewObserved.allowButtons || Utils().demoModeEnabled() {
                    PrimaryQuitButton(viewObserved: viewObserved)
                }
            }
            .padding(.bottom, bottomPadding)
            .padding(.leading, contentWidthPadding)
            .padding(.trailing, contentWidthPadding)
        }
    }
    
    var limitRange: ClosedRange<Date> {
        if viewObserved.daysRemaining > 0 {
            // Do not let the user defer past the point of the approachingWindowTime
            return Date()...Calendar.current.date(byAdding: .day, value: viewObserved.daysRemaining-(imminentWindowTime / 24), to: Date())!
        } else {
            return Date()...Calendar.current.date(byAdding: .day, value: 0, to: Date())!
        }
    }

    func updateDeferralUI() {
        viewObserved.userQuitDeferrals += 1
        viewObserved.userDeferrals = viewObserved.userSessionDeferrals + viewObserved.userQuitDeferrals
        Utils().logUserQuitDeferrals()
        Utils().logUserDeferrals()
        Utils().userInitiatedExit()
    }
    
}

#if DEBUG
// Xcode preview for both light and dark mode
struct SimpleMode_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es"], id: \.self) { id in
                SimpleMode(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            ZStack {
                SimpleMode(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
#endif
