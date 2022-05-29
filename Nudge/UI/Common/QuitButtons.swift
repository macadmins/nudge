//
//  QuitButtons.swift
//  QuitButtons
//
//  Created by Bart Reardon on 31/8/21.
//

import SwiftUI
import Foundation

struct QuitButtons: View {
    @ObservedObject var viewObserved: ViewState

    @State var showDeferView = false

    @State var nudgeEventDate = Utils().getCurrentDate()
    @State var nudgeCustomEventDate = Utils().getCurrentDate()

    let buttonTextMinWidth: CGFloat = 35

    let hourTimeInterval: CGFloat = 3600
    let dayTimeInterval: CGFloat = 86400

    func updateDeferralUI() {
        viewObserved.userQuitDeferrals += 1
        viewObserved.userDeferrals = viewObserved.userSessionDeferrals + viewObserved.userQuitDeferrals
        Utils().logUserQuitDeferrals()
        Utils().logUserDeferrals()
        Utils().userInitiatedExit()
    }

    var body: some View {
        HStack {
            // secondaryQuitButton
            if viewObserved.requireDualQuitButtons {
                HStack(spacing: 20) {
                    if viewObserved.hasClickedSecondaryQuitButton == false {
                        Button {
                            viewObserved.hasClickedSecondaryQuitButton = true
                            userHasClickedSecondaryQuitButton()
                        } label: {
                            Text(secondaryQuitButtonText)
                        }
                        .padding(.leading, -200.0)
                    }
                }
            }
            // primaryQuitButton
            if viewObserved.requireDualQuitButtons == false || viewObserved.hasClickedSecondaryQuitButton {
                HStack(spacing: 20) {
                    if allowUserQuitDeferrals {
                        Menu(customDeferralDropdownText) {
                            Button {
                                Utils().setDeferralTime(deferralTime: nudgeEventDate)
                                updateDeferralUI()
                            } label: {
                                Text(primaryQuitButtonText)
                                    .frame(minWidth: buttonTextMinWidth)
                            }
                            if Utils().allow1HourDeferral() {
                                Button {
                                    nudgeEventDate = Utils().getCurrentDate()
                                    Utils().setDeferralTime(deferralTime: nudgeEventDate.addingTimeInterval(hourTimeInterval))
                                    userHasClickedDeferralQuitButton(deferralTime: nudgeEventDate.addingTimeInterval(hourTimeInterval))
                                    updateDeferralUI()
                                } label: {
                                    Text(oneHourDeferralButtonText)
                                        .frame(minWidth: buttonTextMinWidth)
                                }
                            }
                            if Utils().allow24HourDeferral() {
                                Button {
                                    nudgeEventDate = Utils().getCurrentDate()
                                    Utils().setDeferralTime(deferralTime: nudgeEventDate.addingTimeInterval(dayTimeInterval))
                                    userHasClickedDeferralQuitButton(deferralTime: nudgeEventDate.addingTimeInterval(dayTimeInterval))
                                    updateDeferralUI()
                                } label: {
                                    Text(oneDayDeferralButtonText)
                                        .frame(minWidth: buttonTextMinWidth)
                                }
                            }
                            if Utils().allowCustomDeferral() {
                                Divider()
                                Button {
                                    self.showDeferView.toggle()
                                } label: {
                                    Text(customDeferralButtonText)
                                        .frame(minWidth: buttonTextMinWidth)
                                }
                            }
                        }
                    } else {
                        Button {
                            Utils().userInitiatedExit()
                        } label: {
                            Text(primaryQuitButtonText)
                                .frame(minWidth: buttonTextMinWidth)
                        }
                    }
                }
                .sheet(isPresented: $showDeferView) {
                } content: {
                    DeferView(viewObserved: viewObserved)
                }
            }
        }
        .frame(maxWidth:100, maxHeight: 30)
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct QuitButtons_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es"], id: \.self) { id in
                QuitButtons(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            ZStack {
                QuitButtons(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
#endif
