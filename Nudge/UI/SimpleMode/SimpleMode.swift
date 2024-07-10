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
            AdditionalInfoButton().padding(3) // (?) button
            
            mainContent
                .frame(alignment: .center)
            
            bottomButtons
        }
    }
    
    private var mainContent: some View {
        VStack(alignment: .center, spacing: 10) {
            Spacer()
            CompanyLogo()
            Spacer()
            
            Text(appState.deviceSupportedByOSVersion ? getMainHeader().localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)) : getMainHeaderUnsupported().localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                .font(.title)
            
            remainingTimeView

            if UserInterfaceVariables.showDeferralCount {
                deferralCountView
            }

            Spacer()
            if appState.deviceSupportedByOSVersion {
                Button(action: {
                    UIUtilities().updateDevice()
                }) {
                    Text(UserInterfaceVariables.actionButtonText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                        .frame(minWidth: 120)
                }
                .keyboardShortcut(.defaultAction)
            } else {
                InformationButtonAsAction()
            }
            Spacer()
        }
    }
    
    private var remainingTimeView: some View {
        HStack(spacing: 3.5) {
            if (appState.daysRemaining > 0 && !CommandLineUtilities().demoModeEnabled()) || CommandLineUtilities().demoModeEnabled() {
                Text("Days Remaining To Update:".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                Text(String(appState.daysRemaining))
                    .foregroundColor(colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
            } else if appState.daysRemaining == 0 && !CommandLineUtilities().demoModeEnabled() {
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
    }
    
    private var deferralCountView: some View {
        HStack {
            Text("Deferred Count:".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                .font(.title2)
            Text(String(appState.userDeferrals))
                .foregroundColor(infoTextColor)
                .font(.title2)
        }
    }
    
    private var bottomButtons: some View {
        HStack {
            InformationButton()
            
            if appState.allowButtons || CommandLineUtilities().demoModeEnabled() {
                QuitButtons()
            }
        }
        .padding([.bottom, .leading, .trailing], UIConstants.contentWidthPadding)
    }
    
    private var infoTextColor: Color {
        colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark
    }
}

#if DEBUG
#Preview {
    ForEach(["en", "es"], id: \.self) { id in
        SimpleMode()
            .environmentObject(nudgePrimaryState)
            .previewLayout(.fixed(width: uiConstants.declaredWindowWidth, height: uiConstants.declaredWindowHeight))
            .environment(\.locale, .init(identifier: id))
            .previewDisplayName("SimpleMode (\(id))")
    }
}
#endif
