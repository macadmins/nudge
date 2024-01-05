//
//  CompanyLogo.swift
//  CompanyLogo
//
//  Created by Bart Reardon on 31/8/21.
//

import SwiftUI

struct CompanyLogo: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    private var companyLogoPath: String {
        ImageManager().getCompanyLogoPath(colorScheme: colorScheme)
    }
    
    var body: some View {
        Group {
            if shouldShowCompanyLogo() {
                companyImage
            } else if UIUtilities().showEasterEgg() {
                easterEggView
            } else {
                defaultImage
            }
        }
    }

    private var companyImage: some View {
        Image(nsImage: ImageManager().getCorrectImage(path: companyLogoPath, type: "CompanyLogo"))
            .customResizable(width: logoWidth, height: logoHeight)
    }

    private var defaultImage: some View {
        Image(systemName: "applelogo")
            .customResizable(width: logoWidth, height: logoHeight)
    }
    
    private var easterEggView: some View {
        VStack(spacing: 0) {
            Color.green
            Color.yellow
            Color.orange
            Color.red
            Color.purple
            Color.blue
        }
        .frame(width: logoWidth, height: logoHeight)
        .mask(
            defaultImage
        )
    }
    
    private func shouldShowCompanyLogo() -> Bool {
        companyLogoPath.starts(with: "data:") || FileManager.default.fileExists(atPath: companyLogoPath)
    }
}

#if DEBUG
#Preview {
    CompanyLogo()
        .environmentObject(nudgePrimaryState)
        .previewDisplayName("CompanyLogo")
}
#endif
