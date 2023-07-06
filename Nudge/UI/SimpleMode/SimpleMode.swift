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
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            AdditionalInfoButton() // (?) button
                .padding(3)
            
            VStack(alignment: .center, spacing: 10) {
                Spacer()
                CompanyLogo()
                Spacer()

                HStack {
                    Text(getMainHeader().localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                        .font(.title)
                        .fontWeight(.bold)
                }

                HStack(spacing: 3.5) {
                    if (appState.daysRemaining > 0 && !Utils().demoModeEnabled()) || Utils().demoModeEnabled() {
                        Text("Days Remaining To Update:".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                        Text(String(appState.daysRemaining))
                            .foregroundColor(colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
                    } else if appState.daysRemaining == 0 && !Utils().demoModeEnabled() {
                        Text("Hours Remaining To Update:".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                        Text(String(appState.hoursRemaining))
                            .foregroundColor(appState.differentiateWithoutColor ? .accessibleRed : .red)
                            .fontWeight(.bold)
                    } else {
                        Text("Days Remaining To Update:".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                        Text(String(appState.daysRemaining))
                            .foregroundColor(appState.differentiateWithoutColor ? .accessibleRed : .red)
                            .fontWeight(.bold)
                        
                    }
                }

                if showDeferralCount {
                    HStack{
                        Text("Deferred Count:".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                            .font(.title2)
                        Text(String(appState.userDeferrals))
                            .foregroundColor(colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                } else {
                    HStack{
                        Text("Deferred Count:".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                            .font(.title2)
                        Text(String(appState.userDeferrals))
                            .foregroundColor(colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .hidden()
                }
                Spacer()

                Button(action: {
                    Utils().updateDevice()
                }) {
                    Text(actionButtonText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                        .frame(minWidth: 120)
                }
                .keyboardShortcut(.defaultAction)
                Spacer()
            }
            .frame(alignment: .center)

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
        SimpleMode()
            .environmentObject(nudgePrimaryState)
            .previewLayout(.fixed(width: declaredWindowWidth, height: declaredWindowHeight))
            .environment(\.locale, .init(identifier: id))
            .previewDisplayName("SimpleMode (\(id))")
    }
}
#endif
