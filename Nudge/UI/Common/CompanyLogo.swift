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
                    .overlay(companyImageOverlay, alignment: .topTrailing)
            } else if UIUtilities().showEasterEgg() {
                easterEggView
            } else {
                defaultImage
            }
        }
    }

    private var companyImage: some View {
        AsyncImage(url: UIUtilities().createCorrectURLType(from: companyLogoPath)) { phase in
            switch phase {
                case .empty:
                    Image(systemName: "square.dashed")
                        .customResizable(width: uiConstants.logoWidth, height: uiConstants.logoHeight)
                        .customFontWeight(fontWeight: .ultraLight)
                        .opacity(0.05)
                case .failure:
                    Image(systemName: "questionmark.square.dashed")
                        .customResizable(width: uiConstants.logoWidth, height: uiConstants.logoHeight)
                        .customFontWeight(fontWeight: .ultraLight)
                        .opacity(0.05)
                case .success(let image):
                    image
                        .customResizable(width: uiConstants.logoWidth, height: uiConstants.logoHeight)
                @unknown default:
                    EmptyView()
            }
        }
    }

    private var companyImageOverlay: some View {
        guard !appState.deviceSupportedByOSVersion else { return AnyView(EmptyView()) }
        return AnyView(
            Image(systemName: "exclamationmark.triangle")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.red)
                .font(.title)
        )
    }

    private var defaultImage: some View {
        Image(systemName: "applelogo")
            .customResizable(width: uiConstants.logoWidth, height: uiConstants.logoHeight)
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
        .frame(width: uiConstants.logoWidth, height: uiConstants.logoHeight)
        .mask(
            defaultImage
        )
    }
    
    private func shouldShowCompanyLogo() -> Bool {
        ["data:", "https://", "http://", "file://"].contains(where: companyLogoPath.starts(with:)) || FileManager.default.fileExists(atPath: companyLogoPath)
    }
}

#if DEBUG
#Preview {
    CompanyLogo()
        .environmentObject(nudgePrimaryState)
        .previewDisplayName("CompanyLogo")
}
#endif
