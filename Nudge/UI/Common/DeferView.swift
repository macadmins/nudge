//
//  DeferView.swift
//  Nudge
//
//  Created by Erik Gomez on 8/16/21.
//

import Foundation
import SwiftUI

// Sheet view for Device Information
struct DeferView: View {
    @ObservedObject var viewObserved: ViewState
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    
    @State var nudgeCustomEventDate = Date()
    
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Button(
                    action: {
                        self.presentationMode.wrappedValue.dismiss()})
                {
                    Image(systemName: "xmark.circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(differentiateWithoutColor ? Color(red: 230 / 255, green: 97 / 255, blue: 0 / 255) : .red)
                }
                .keyboardShortcut(.escape)
                .buttonStyle(.plain)
                .help("Click to close".localized(desiredLanguage: getDesiredLanguage()))
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
                DatePicker("", selection: $nudgeCustomEventDate, in: limitRange)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                DatePicker("", selection: $nudgeCustomEventDate, in: limitRange, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
                    .frame(maxWidth: 100)
            }
            // make space left and right of the stack
            .padding(.leading, 30)
            .padding(.trailing, 30)
            
            Divider()
            
            Button {
                nudgeDefaults.set(nudgeCustomEventDate, forKey: "deferRunUntil")
                userHasClickedDeferralQuitButton(deferralTime: nudgeCustomEventDate)
                viewObserved.shouldExit = true
                viewObserved.userQuitDeferrals += 1
                viewObserved.userDeferrals = viewObserved.userSessionDeferrals + viewObserved.userQuitDeferrals
                Utils().logUserQuitDeferrals()
                Utils().logUserDeferrals()
                Utils().userInitiatedExit()
            } label: {
                Text("Defer")
                    .frame(minWidth: 35)
            }
            // a bit of space at the bottom to raise the Defer button away from the very edge
            .padding(.bottom, 10)
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
}

#if DEBUG
// Xcode preview for both light and dark mode
struct DeferView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es"], id: \.self) { id in
                DeferView(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            ZStack {
                DeferView(viewObserved: nudgePrimaryState)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
#endif

