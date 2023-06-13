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

    var body: some View {
        VStack {
            // display the (?) info button
            AdditionalInfoButton()
                .padding(3)
            
            VStack(alignment: .center, spacing: 10) {
                Spacer()
                // Company Logo
                CompanyLogo()
                Spacer()
                
                // mainHeader
                HStack {
                    Text(getMainHeader().localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                // Days or Hours Remaining
                HStack(spacing: 3.5) {
                    if (appState.daysRemaining > 0 && !Utils().demoModeEnabled()) || Utils().demoModeEnabled() {
                        Text("Days Remaining To Update:".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                        Text(String(appState.daysRemaining))
                            .foregroundColor(appState.colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
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
                
                // Deferral Count
                if showDeferralCount {
                    HStack{
                        Text("Deferred Count:".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                            .font(.title2)
                        Text(String(appState.userDeferrals))
                            .foregroundColor(appState.colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                } else {
                    HStack{
                        Text("Deferred Count:".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                            .font(.title2)
                        Text(String(appState.userDeferrals))
                            .foregroundColor(appState.colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
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
                    Text(actionButtonText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
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
// Xcode preview for both light and dark mode
struct SimpleMode_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["en", "es"], id: \.self) { id in
            SimpleMode()
                .environmentObject(nudgePrimaryState)
                .previewLayout(.fixed(width: declaredWindowWidth, height: declaredWindowHeight))
                .environment(\.locale, .init(identifier: id))
                .previewDisplayName("SimpleMode (\(id))")
        }
    }
}
#endif
