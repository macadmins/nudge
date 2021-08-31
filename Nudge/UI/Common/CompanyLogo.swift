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
    
    let defaultWidth : CGFloat = 200
    let defaultHeight : CGFloat = 150
    
    var logoWidth  : CGFloat
    var logoHeight : CGFloat
    
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
                Image(systemName: "applelogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaledToFit()
                    .frame(width: logoWidth, height: logoHeight)
            }
        }
    }
}

