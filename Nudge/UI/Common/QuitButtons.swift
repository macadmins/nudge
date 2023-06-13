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
            // secondaryQuitButton
            if appState.requireDualQuitButtons {
                HStack(spacing: 20) {
                    if appState.hasClickedSecondaryQuitButton == false {
                        Button(
                            action: {
                                // TODO: Xcode 15 Compiler warning suddenly. Investigate
                                appState.hasClickedSecondaryQuitButton = true
                                userHasClickedSecondaryQuitButton()
                            }, label: {
                                Text(secondaryQuitButtonText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                            }
                        )
                        .padding(.leading, -200.0)
                    }
                }
                .frame(maxWidth:100, maxHeight: 30)
            }
            // primaryQuitButton
            if appState.requireDualQuitButtons == false || appState.hasClickedSecondaryQuitButton {
                HStack {
                    if allowUserQuitDeferrals {
                        Menu {
                            if allowLaterDeferralButton {
                                Button {
                                    Utils().setDeferralTime(deferralTime: appState.nudgeEventDate)
                                    updateDeferralUI()
                                } label: {
                                    Text(primaryQuitButtonText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                                        .frame(minWidth: buttonTextMinWidth)
                                }
                            }
                            if Utils().allow1HourDeferral() {
                                Button {
                                    appState.nudgeEventDate = Utils().getCurrentDate()
                                    Utils().setDeferralTime(deferralTime: appState.nudgeEventDate.addingTimeInterval(hourTimeInterval))
                                    userHasClickedDeferralQuitButton(deferralTime: appState.nudgeEventDate.addingTimeInterval(hourTimeInterval))
                                    updateDeferralUI()
                                } label: {
                                    Text(oneHourDeferralButtonText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                                        .frame(minWidth: buttonTextMinWidth)
                                }
                            }
                            if Utils().allow24HourDeferral() {
                                Button {
                                    appState.nudgeEventDate = Utils().getCurrentDate()
                                    Utils().setDeferralTime(deferralTime: appState.nudgeEventDate.addingTimeInterval(dayTimeInterval))
                                    userHasClickedDeferralQuitButton(deferralTime: appState.nudgeEventDate.addingTimeInterval(dayTimeInterval))
                                    updateDeferralUI()
                                } label: {
                                    Text(oneDayDeferralButtonText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                                        .frame(minWidth: buttonTextMinWidth)
                                }
                            }
                            if Utils().allowCustomDeferral() {
                                Divider()
                                Button {
                                    appState.deferViewIsPresented = true
                                } label: {
                                    Text(customDeferralButtonText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                                        .frame(minWidth: buttonTextMinWidth)
                                }
                            }
                        }
                    label: {
                        Text(customDeferralDropdownText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                    }
                    .frame(maxWidth:215, maxHeight: 30)
                    } else {
                        Button {
                            Utils().userInitiatedExit()
                        } label: {
                            Text(primaryQuitButtonText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                                .frame(minWidth: buttonTextMinWidth)
                        }
                    }
                }
                .sheet(isPresented: $appState.deferViewIsPresented) {
                } content: {
                    DeferView()
                }
            }
        }
    }
    
    func updateDeferralUI() {
        appState.userQuitDeferrals += 1
        appState.userDeferrals = appState.userSessionDeferrals + appState.userQuitDeferrals
        Utils().logUserQuitDeferrals()
        Utils().logUserDeferrals()
        Utils().userInitiatedExit()
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct QuitButtons_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["en", "es"], id: \.self) { id in
            QuitButtons()
                .environmentObject(nudgePrimaryState)
                .environment(\.locale, .init(identifier: id))
                .previewDisplayName("QuitButtons (\(id))")
        }
    }
}
#endif
