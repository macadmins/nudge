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
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

    let bottomPadding: CGFloat = 10
    let contentWidthPadding: CGFloat = 25
    
    let logoWidth: CGFloat = 200
    let logoHeight: CGFloat = 150

    // Nudge UI
    var body: some View {
        VStack {
            // display the (?) info button
            AdditionalInfoButton()
                .padding(3)

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
 
                // Days or Hours Remaining
                HStack(spacing: 3.5) {
                    if (viewObserved.daysRemaining > 0 && !Utils().demoModeEnabled()) || Utils().demoModeEnabled() {
                        Text("Days Remaining To Update:".localized(desiredLanguage: getDesiredLanguage()))
                        Text(String(viewObserved.daysRemaining))
                            .foregroundColor(.secondary)
                    } else if viewObserved.daysRemaining == 0 && !Utils().demoModeEnabled() {
                            Text("Hours Remaining To Update:".localized(desiredLanguage: getDesiredLanguage()))
                            Text(String(viewObserved.hoursRemaining))
                                .foregroundColor(differentiateWithoutColor ? Color(red: 230 / 255, green: 97 / 255, blue: 0 / 255) : .red)
                                .fontWeight(.bold)
                    } else {
                        Text("Days Remaining To Update:".localized(desiredLanguage: getDesiredLanguage()))
                        Text(String(viewObserved.daysRemaining))
                            .foregroundColor(differentiateWithoutColor ? Color(red: 230 / 255, green: 97 / 255, blue: 0 / 255) : .red)
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
                    QuitButtons(viewObserved: viewObserved)
                }
            }
            .padding(.bottom, bottomPadding)
            .padding(.leading, contentWidthPadding)
            .padding(.trailing, contentWidthPadding)
        }
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
