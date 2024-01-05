//
//  DeferView.swift
//  Nudge
//
//  Created by Erik Gomez on 8/16/21.
//

import Foundation
import SwiftUI

struct DeferView: View {
    @EnvironmentObject var appState: AppState
    
    private let edgePadding: CGFloat = 4
    private let horizontalPadding: CGFloat = 30
    private let bottomPadding: CGFloat = 10
    
    var body: some View {
        VStack(alignment: .center) {
            closeButton
            datePickerStack
            Divider()
            // a bit of space at the bottom to raise the Defer button away from the very edge
            deferButton
                .padding(.bottom, bottomPadding)
        }
        .background(Color(NSColor.windowBackgroundColor))
        
        
    }
    
    private var closeButton: some View {
        HStack {
            Button(action: { appState.deferViewIsPresented = false }) {
                CloseButton()
            }
            .keyboardShortcut(.escape)
            .buttonStyle(.plain)
            .help("Click to close".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
            .onHoverEffect()
            .padding(edgePadding)
            Spacer()
        }
    }
    
    private var datePickerStack: some View {
        // We have two DatePickers because DatePicker is non-ideal
        VStack {
            DatePicker("", selection: $appState.nudgeCustomEventDate, in: limitRange)
                .datePickerStyle(.graphical)
                .labelsHidden()
            DatePicker("", selection: $appState.nudgeCustomEventDate, in: limitRange, displayedComponents: [.hourAndMinute])
                .labelsHidden()
                .frame(maxWidth: 100)
        }
        .padding(.horizontal, horizontalPadding)
    }
    
    private var deferButton: some View {
        Button(action: deferAction) {
            Text(UserInterfaceVariables.customDeferralDropdownText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                .frame(minWidth: 35)
        }
    }
    
    private func deferAction() {
        UIUtilities().setDeferralTime(deferralTime: appState.nudgeCustomEventDate)
        userHasClickedDeferralQuitButton(deferralTime: appState.nudgeCustomEventDate)
        appState.shouldExit = true
        appState.userQuitDeferrals += 1
        appState.userDeferrals = appState.userSessionDeferrals + appState.userQuitDeferrals
        LoggerUtilities().logUserQuitDeferrals()
        LoggerUtilities().logUserDeferrals()
        UIUtilities().userInitiatedExit()
    }
    
    private var limitRange: ClosedRange<Date> {
        let windowTime = [ "approachingWindowTime": UserExperienceVariables.approachingWindowTime,
                           "imminentWindowTime": UserExperienceVariables.imminentWindowTime ]
        let daysToAdd = appState.daysRemaining > 0 ? appState.daysRemaining - (windowTime[UserExperienceVariables.calendarDeferralUnit] ?? UserExperienceVariables.imminentWindowTime / 24) : 0
        // Do not let the user defer past the point of the windowTime
        return DateManager().getCurrentDate()...Calendar.current.date(byAdding: .day, value: daysToAdd, to: DateManager().getCurrentDate())!
    }
}

#if DEBUG
#Preview {
    ForEach(["en", "es"], id: \.self) { id in
        DeferView()
            .environmentObject(nudgePrimaryState)
            .environment(\.locale, .init(identifier: id))
            .previewDisplayName("DeferView (\(id))")
    }
}
#endif
