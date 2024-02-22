//
//  QuitButtons.swift
//  QuitButtons
//
//  Created by Bart Reardon on 31/8/21.
//

import Foundation
import SwiftUI

struct QuitButtons: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            if shouldShowSecondaryQuitButton {
                secondaryQuitButton
                    .frame(maxWidth:215, maxHeight: 30)
                Spacer()
            }
            if shouldShowPrimaryQuitButton {
                Spacer()
                primaryQuitButton
                    .frame(maxWidth:215, maxHeight: 30)
            }
        }
        .sheet(isPresented: $appState.deferViewIsPresented) {
            DeferView()
        }
    }

    private var customDeferralButton: some View {
        Button(action: { appState.deferViewIsPresented = true }) {
            Text(UserInterfaceVariables.customDeferralButtonText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
        }
    }

    private func deferAction(by timeInterval: TimeInterval) {
        appState.nudgeEventDate = DateManager().getCurrentDate().addingTimeInterval(timeInterval)
        UIUtilities().setDeferralTime(deferralTime: appState.nudgeEventDate)
        userHasClickedDeferralQuitButton(deferralTime: appState.nudgeEventDate)
        updateDeferralUI()
    }

    private func deferralButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
        }
    }

    private var deferralMenu: some View {
        Menu {
            deferralOptions
        } label: {
            Text(UserInterfaceVariables.customDeferralDropdownText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
        }
    }

    private var deferralOptions: some View {
        Group {
            if UserExperienceVariables.allowLaterDeferralButton {
                deferralButton(title: UserInterfaceVariables.primaryQuitButtonText, action: standardDeferralAction)
            }
            if AppStateManager().allow1HourDeferral() {
                deferralButton(title: UserInterfaceVariables.oneHourDeferralButtonText, action: { deferAction(by: Intervals.hourTimeInterval) })
            }
            if AppStateManager().allow24HourDeferral() {
                deferralButton(title: UserInterfaceVariables.oneDayDeferralButtonText, action: { deferAction(by: Intervals.dayTimeInterval) })
            }
            if AppStateManager().allowCustomDeferral() {
                customDeferralButton
            }
        }
    }

    private var primaryQuitButton: some View {
        Group {
            if UserExperienceVariables.allowUserQuitDeferrals {
                deferralMenu
            } else {
                standardQuitButton
            }
        }
    }
    
    private var secondaryQuitButton: some View {
        Button(action: secondaryQuitButtonAction) {
            Text(UserInterfaceVariables.secondaryQuitButtonText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
        }
    }

    private func secondaryQuitButtonAction() {
        appState.hasClickedSecondaryQuitButton = true
        userHasClickedSecondaryQuitButton()
    }

    // Determines if the secondary quit button should be shown
    private var shouldShowSecondaryQuitButton: Bool {
        appState.requireDualQuitButtons && !appState.hasClickedSecondaryQuitButton
    }
    
    // Determines if the primary quit button should be shown
    private var shouldShowPrimaryQuitButton: Bool {
        !appState.requireDualQuitButtons || appState.hasClickedSecondaryQuitButton
    }

    private func standardDeferralAction() {
        appState.nudgeEventDate = DateManager().getCurrentDate()
        UIUtilities().setDeferralTime(deferralTime: appState.nudgeEventDate)
        updateDeferralUI()
    }
    
    private var standardQuitButton: some View {
        Button(action: UIUtilities().userInitiatedExit) {
            Text(UserInterfaceVariables.primaryQuitButtonText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
        }
    }
    
    private func updateDeferralUI() {
        // Update deferral UI logic
        appState.userQuitDeferrals += 1
        appState.userDeferrals = appState.userSessionDeferrals + appState.userQuitDeferrals
        LoggerUtilities().logUserSessionDeferrals()
        LoggerUtilities().logUserQuitDeferrals()
        LoggerUtilities().logUserDeferrals()
        UIUtilities().userInitiatedExit()
    }
}

#if DEBUG
#Preview {
    ForEach(["en", "es"], id: \.self) { id in
        QuitButtons()
            .environmentObject(nudgePrimaryState)
            .environment(\.locale, .init(identifier: id))
            .previewDisplayName("QuitButtons (\(id))")
    }
}
#endif
