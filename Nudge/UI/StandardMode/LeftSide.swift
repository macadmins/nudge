//
//  LeftSide.swift
//  Nudge
//
//  Created by Erik Gomez on 2/18/21.
//

import Foundation
import SwiftUI

// StandardModeLeftSide
struct StandardModeLeftSide: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    private let bottomPadding: CGFloat = 10
    private let interItemSpacing: CGFloat = 20
    private let interLineSpacing: CGFloat = 10
    
    var body: some View {
        VStack {
            contentStack
            Spacer() // Force buttons to the bottom
        }
        .padding(.bottom, bottomPadding)
    }
    
    private var contentStack: some View {
        VStack(alignment: .center, spacing: interItemSpacing) {
            AdditionalInfoButton().padding(3) // (?) button
            CompanyLogo()
            Divider().padding(.horizontal, UIConstants.contentWidthPadding)
            informationStack
        }
    }
    
    private var informationStack: some View {
        VStack(alignment: .center, spacing: interLineSpacing) {
            InfoRow(label: "Required OS Version:", value: String(appState.requiredMinimumOSVersion), boldText: true)
            if UserInterfaceVariables.showRequiredInstallationDate {
                InfoRow(label: "Required Date:", value: DateManager().coerceDateToString(date: requiredInstallationDate, formatterString: UserInterfaceVariables.requiredInstallationDisplayFormat))
            }
            if OptionalFeatureVariables.utilizeSOFAFeed && UserInterfaceVariables.showActivelyExploitedCVEs {
                InfoRow(label: "Actively Exploited CVEs:", value: String(appState.activelyExploitedCVEs).capitalized, isHighlighted: appState.activelyExploitedCVEs ? true : false, boldText: appState.activelyExploitedCVEs)
            }
            InfoRow(label: "Current OS Version:", value: GlobalVariables.currentOSVersion)
            remainingTimeRow
            if UserInterfaceVariables.showDeferralCount {
                InfoRow(label: "Deferred Count:", value: String(appState.userDeferrals))
            }
        }
        .padding(.horizontal, UIConstants.contentWidthPadding)
    }
    
    private var remainingTimeRow: some View {
        Group {
            if shouldShowDaysRemaining {
                InfoRow(label: "Days Remaining To Update:", value: String(appState.daysRemaining), isHighlighted: 0 > appState.daysRemaining ? true : false)
            } else {
                InfoRow(label: "Hours Remaining To Update:", value: String(appState.hoursRemaining), isHighlighted: true)
            }
        }
    }
    
    private var shouldShowDaysRemaining: Bool {
        ((appState.daysRemaining > 0 || 0 > appState.hoursRemaining) && !CommandLineUtilities().demoModeEnabled()) || CommandLineUtilities().demoModeEnabled()
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var isHighlighted: Bool = false
    var boldText: Bool = false
    
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Text(label.localized(desiredLanguage: getDesiredLanguage(locale: appState.locale)))
                .fontWeight(boldText ? .bold : .regular)
            Spacer()
            if isHighlighted {
                Text(value)
                    .foregroundColor(appState.differentiateWithoutColor ? .accessibleRed : .red)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.01)
            } else {
                Text(value)
                    .foregroundColor(colorScheme == .light ? .accessibleSecondaryLight : .accessibleSecondaryDark)
                    .fontWeight(boldText ? .bold : .regular)
                    .minimumScaleFactor(0.01)
            }
        }
        .lineLimit(1)
    }
}

#if DEBUG
#Preview {
    ForEach(["en", "es"], id: \.self) { id in
        StandardModeLeftSide()
            .environmentObject(nudgePrimaryState)
            .environment(\.locale, .init(identifier: id))
            .previewDisplayName("LeftSide (\(id))")
    }
}
#endif
