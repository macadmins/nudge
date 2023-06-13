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
    
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Button(
                    action: {
                        appState.deferViewIsPresented = false
                    }
                )
                {
                    Image(systemName: "xmark.circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.red)
                }
                .keyboardShortcut(.escape)
                .buttonStyle(.plain)
                .help("Click to close".localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                .onHover { inside in
                    if inside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                // pulls the button away from the very edge of the view. Value of 4 seems a nice distance
                .padding(4)
                Spacer()
            }
            
            VStack() {
                // We have two DatePickers because DatePicker is non-ideal
                DatePicker("", selection: $appState.nudgeCustomEventDate, in: limitRange)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                DatePicker("", selection: $appState.nudgeCustomEventDate, in: limitRange, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
                    .frame(maxWidth: 100)
            }
            // make space left and right of the stack
            .padding(.leading, 30)
            .padding(.trailing, 30)
            
            Divider()
            
            Button {
                Utils().setDeferralTime(deferralTime: appState.nudgeCustomEventDate)
                userHasClickedDeferralQuitButton(deferralTime: appState.nudgeCustomEventDate)
                appState.shouldExit = true
                appState.userQuitDeferrals += 1
                appState.userDeferrals = appState.userSessionDeferrals + appState.userQuitDeferrals
                Utils().logUserQuitDeferrals()
                Utils().logUserDeferrals()
                Utils().userInitiatedExit()
            } label: {
                Text(customDeferralDropdownText.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                    .frame(minWidth: 35)
            }
            // a bit of space at the bottom to raise the Defer button away from the very edge
            .padding(.bottom, 10)
        }
    }
    var limitRange: ClosedRange<Date> {
        var windowTime: Int
        if calendarDeferralUnit == "approachingWindowTime" {
            windowTime = (approachingWindowTime / 24)
        } else if calendarDeferralUnit == "imminentWindowTime" {
            windowTime = (imminentWindowTime / 24)
        } else {
            windowTime = (imminentWindowTime / 24)
        }
        if appState.daysRemaining > 0 {
            // Do not let the user defer past the point of the windowTime
            return Utils().getCurrentDate()...Calendar.current.date(byAdding: .day, value: appState.daysRemaining-(windowTime), to: Utils().getCurrentDate())!
        } else {
            return Utils().getCurrentDate()...Calendar.current.date(byAdding: .day, value: 0, to: Utils().getCurrentDate())!
        }
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct DeferView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["en", "es"], id: \.self) { id in
            DeferView()
                .environmentObject(nudgePrimaryState)
                .environment(\.locale, .init(identifier: id))
                .previewDisplayName("DeferView (\(id))")
        }
    }
}
#endif
