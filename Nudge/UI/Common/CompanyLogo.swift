//
//  CompanyLogo.swift
//  CompanyLogo
//
//  Created by Bart Reardon on 31/8/21.
//

import SwiftUI

struct CompanyLogo: View {
    
    // Get the color scheme so we can dynamically change properties
    @Environment(\.colorScheme) var colorScheme
    
    let defaultWidth: CGFloat = 200
    let defaultHeight: CGFloat = 150
    
    var logoWidth: CGFloat
    var logoHeight: CGFloat
    
    init(width: CGFloat?, height: CGFloat?) {
        logoWidth = width ?? defaultWidth
        logoHeight = height ?? defaultHeight
    }
    
    var body: some View {
        let darkMode = colorScheme == .dark
        let companyLogoPath = Utils().getCompanyLogoPath(darkMode: darkMode)
        
        // Company Logo
        Group {
            if FileManager.default.fileExists(atPath: companyLogoPath) {
                Image(nsImage: Utils().createImageData(fileImagePath: companyLogoPath))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaledToFit()
                    .frame(width: logoWidth, height: logoHeight)
            } else {
                if Utils().showEasterEgg() {
                    // https://twitter.com/onmyway133/status/1530135315071000576?s=20&t=_vIIIqcSEiUii15GIBr8nw
                    VStack(spacing: 0) {
                        Color.green
                        Color.green
                        Color.green
                        Color.yellow
                        Color.orange
                        Color.red
                        Color.purple
                        Color.blue
                    }
                    .frame(width: logoWidth, height: logoHeight)
                    .mask(
                        Image(systemName: "applelogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaledToFit()
                    )
                } else {
                    Image(systemName: "applelogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaledToFit()
                        .frame(width: logoWidth, height: logoHeight)
                }
            }
        }
    }
}

#if DEBUG
// Xcode preview for both light and dark mode
struct CompanyLogo_Previews: PreviewProvider {
    static var previews: some View {
        CompanyLogo(width: 200, height: 150)
    }
}
#endif

