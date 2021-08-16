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
                        .foregroundColor(.red)
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
                .frame(width: 30, height: 30)
                Spacer()
            }
            DatePicker("", selection: $nudgeCustomEventDate, in: limitRange, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .labelsHidden()
                .frame(width: 150, height: 150, alignment: .center)
                .clipped()
            DatePicker("", selection: $nudgeCustomEventDate, in: limitRange, displayedComponents: [.hourAndMinute])
                .datePickerStyle(.stepperField)
                .labelsHidden()
                .frame(maxWidth: 75)
            Divider()
            HStack {
                Button {
                    nudgeDefaults.set(nudgeCustomEventDate, forKey: "deferRunUntil")
                    userHasClickedDeferralQuitButton(deferralTime: nudgeCustomEventDate)
                    viewObserved.shouldExit.toggle()
                    self.presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Defer")
                        .frame(minWidth: 35)
                }
            }
        }
        .frame(width: 280, height: 280)
    }
    var limitRange: ClosedRange<Date> {
        let daysRemaining = Utils().getNumberOfDaysBetween()
        if daysRemaining > 0 {
            // Do not let the user defer past the point of the approachingWindowTime
            return Date()...Calendar.current.date(byAdding: .day, value: daysRemaining-(imminentWindowTime / 24), to: Date())!
        } else {
            return Date()...Calendar.current.date(byAdding: .day, value: 0, to: Date())!
        }
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct DeviceViewPreview: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(["en", "es"], id: \.self) { id in
                DeferView(viewObserved: ViewState())
                    .preferredColorScheme(.light)
                    .environment(\.locale, .init(identifier: id))
            }
            DeferView(viewObserved: ViewState())
                .preferredColorScheme(.dark)
        }
    }
}
#endif

