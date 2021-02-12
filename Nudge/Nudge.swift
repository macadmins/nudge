//
//  Nudge.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import Foundation
import SwiftUI

// Primary Nudge UI
struct Nudge: View {
    // Get the color scheme so we can dynamically change properties
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    @EnvironmentObject var manager: PolicyManager

    // State variables
    @State var systemConsoleUsername = Utils().getSystemConsoleUsername()
    @State var serialNumber = Utils().getSerialNumber()
    @State var cpuType = Utils().getCPUTypeString()
    @State var daysRemaining = Utils().getNumberOfDaysBetween()
    @State var requireDualQuitButtons = Utils().requireDualQuitButtons()
    @State var pastRequiredInstallationDate = Utils().pastRequiredInstallationDate()
    @State var hasClickedSecondaryQuitButton = false
    @State var deferralCountUI = 0
    
    // Modal view for screenshot
    @State var showSSDetail = false
    
    // Get the screen frame
    var screen = NSScreen.main?.visibleFrame
    
    // Setup the main refresh timer that controls the child refresh logic
    let nudgeRefreshCycleTimer = Timer.publish(every: Double(nudgeRefreshCycle), on: .main, in: .common).autoconnect()

    // Nudge UI
    var body: some View {
        if simpleMode {
            VStack{
                // Company Logo
                if colorScheme == .dark {
                    if FileManager.default.fileExists(atPath: iconDarkPath) {
                        Image(nsImage: Utils().createImageData(fileImagePath: iconDarkPath))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaledToFit()
                            .frame(width: 300, height: 225)
                    } else {
                        Image(systemName: "applelogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaledToFit()
                            .frame(width: 200, height: 150)
                            .padding(.vertical, 50)
                    }
                } else {
                    if FileManager.default.fileExists(atPath: iconLightPath) {
                        Image(nsImage: Utils().createImageData(fileImagePath: iconLightPath))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaledToFit()
                            .frame(width: 300, height: 225)
                            .padding(.vertical, 2)
                    } else {
                        Image(systemName: "applelogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaledToFit()
                            .frame(width: 200, height: 150)
                            .padding(.vertical, 50)
                    }
                }

                // mainContent Header
                HStack {
                    Text(mainContentHeader)
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.vertical, 2)

                // Days Remaining
                HStack {
                    Text("Days remaining to update:")
                        .font(.title2)
                    if self.daysRemaining <= 0 {
                        Text(String(0))
                            .font(.title2)
                            .fontWeight(.bold)
                    } else {
                        Text(String(self.daysRemaining))
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                .padding(.vertical, 2)
                
                // actionButton
                Button(action: Utils().updateDevice, label: {
                    Text(actionButtonText)
                        .frame(minWidth: 100)
                  }
                )
                .keyboardShortcut(.defaultAction)
                .padding(.vertical, 2)

                // primaryQuitButton
                Button(action: {AppKit.NSApp.terminate(nil)}, label: {
                    Text(primaryQuitButtonText)
                        .frame(minWidth: 100)
                    }
                )
                .padding(.vertical, 2)
                
                // More Info
                // https://developer.apple.com/documentation/swiftui/openurlaction
                HStack {
                    // Force the button to the right with a spacer
                    Spacer()
                    // informationButton
                    if informationButtonPath != "" {
                        Button(action: Utils().openMoreInfo, label: {
                            Text(informationButtonText)
                          }
                        )
                        .buttonStyle(BorderlessButtonStyle())
                        .padding(.trailing, 20)
                    }
                }
                // https://www.hackingwithswift.com/books/ios-swiftui/running-code-when-our-app-launches
                .onAppear(perform: nudgeStartLogic)
            }
            .frame(width: 900, height: 450)
        } else {
            HStack(spacing: 0){
                // Left side of Nudge
                VStack{
                    // Company Logo
                    if colorScheme == .dark {
                        if FileManager.default.fileExists(atPath: iconDarkPath) {
                            Image(nsImage: Utils().createImageData(fileImagePath: iconDarkPath))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaledToFit()
                                .frame(width: 200, height: 150)
                        } else {
                            Image(systemName: "applelogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaledToFit()
                                .frame(width: 200, height: 150)
                        }
                    } else {
                        if FileManager.default.fileExists(atPath: iconLightPath) {
                            Image(nsImage: Utils().createImageData(fileImagePath: iconLightPath))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaledToFit()
                                .frame(width: 200, height: 150)
                        } else {
                            Image(systemName: "applelogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaledToFit()
                                .frame(width: 200, height: 150)
                        }
                    }

                    // Horizontal line
                    HStack{
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(height: 1)
                    }
                    .frame(width: 300)
                    
                    // Can only have 10 objects per stack unless you hack it and use groups
                    Group {
                        // Required OS Version
                        HStack{
                            Text("Required OS Version: ")
                                .fontWeight(.bold)
                            Spacer()
                            Text(String(requiredMinimumOSVersion).capitalized)
                                .foregroundColor(.secondary)
                                .fontWeight(.bold)
                        }
                        .padding(.vertical, 1)
                        
                        // Current OS Version
                        HStack{
                            Text("Current OS Version: ")
                            Spacer()
                            Text(manager.current.description)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 1)
                        
                        // Username
                        HStack{
                            Text("Username: ")
                            Spacer()
                            Text(self.systemConsoleUsername)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 1)

                        // Serial Number
                        HStack{
                            Text("Serial Number: ")
                            Spacer()
                            Text(self.serialNumber)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 1)

                        // Architecture
                        HStack{
                            Text("Architecture: ")
                            Spacer()
                            Text(self.cpuType)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 1)

                        // Days Remaining
                        HStack{
                            Text("Days remaining to update: ")
                            Spacer()
                            if self.daysRemaining <= 0 {
                                Text(String(0))
                                    .foregroundColor(.secondary)
                            } else {
                                Text(String(self.daysRemaining))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 1)

                        // Deferral Count
                        HStack{
                            Text("Deferral Count: ")
                            Spacer()
                            Text(String(self.deferralCountUI))
                                .onReceive(nudgeRefreshCycleTimer) { _ in
                                    if needToActivateNudge(deferralCountVar: deferralCount, lastRefreshTimeVar: lastRefreshTime) {
                                        self.deferralCountUI += 1
                                    }
                                }
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.trailing, 10)

                    // Force buttons to the bottom with a spacer
                    Spacer()

                    // More Info
                    // https://developer.apple.com/documentation/swiftui/openurlaction
                    HStack(alignment: .top) {
                        // informationButton
                        if informationButtonPath != "" {
                            Button(action: Utils().openMoreInfo, label: {
                                Text(informationButtonText)
                              }
                            )
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        // Force the button to the left with a spacer
                        Spacer()
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 55)
                }
                .frame(width: 300, height: 525)
                
                // Vertical Line
                VStack{
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 1)
                }
                .frame(height: 525)

                // Right side of Nudge
                VStack{
                    // mainHeader Text
                    HStack {
                        Text(getMainHeader())
                            .font(.largeTitle)
                    }
                    .frame(width: 550)

                    // subHeader Text
                    HStack {
                        Text(subHeader)
                            .font(.body)
                    }
                    .padding(.vertical, 0.5)
                    .frame(width: 550)

                    // mainContent Header
                    HStack {
                        Text(mainContentHeader)
                            .font(.body)
                            .fontWeight(.bold)
                    }
                    .padding(.vertical, 0.5)
                    .frame(width: 550)

                    VStack(alignment: .leading) {
                        // mainContent Text
                        Text(mainContentText)
                            .font(.body)
                            .fontWeight(.regular)
                            .multilineTextAlignment(.leading)
                            //.frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 0.5)

                    // Company Screenshot
                        HStack {
                            Spacer()
                            Group{
                                if colorScheme == .dark && FileManager.default.fileExists(atPath: screenShotDarkPath) {
                                    Image(nsImage: Utils().createImageData(fileImagePath: screenShotDarkPath))
                                        .resizable().scaledToFit()
                                        .aspectRatio(contentMode: .fit)
                                } else if colorScheme == .light && FileManager.default.fileExists(atPath: screenShotLightPath) {
                                    Image(nsImage: Utils().createImageData(fileImagePath: screenShotLightPath))
                                        .resizable().scaledToFit()
                                        .aspectRatio(contentMode: .fit)
                                } else {
                                    Image("CompanyScreenshotIcon")
                                        .resizable().scaledToFit()
                                        .aspectRatio(contentMode: .fit)
                                }
                                Button(action: {
                                    self.showSSDetail.toggle()
                                }) {
                                    Image(systemName: "plus.magnifyingglass")
                                }
                                .padding(.leading, -15)
                                .sheet(isPresented: $showSSDetail) {
                                    screenShotZoom()
                                }
                                .help("Click to zoom into screenshot")
                            }
                            Spacer()
                        }
                    }
                    .padding(.vertical, 0.5)
                    .frame(width: 550)

                    // Force buttons to the bottom with a spacer
                    Spacer()
                    
                    // lowerHeader
                    VStack(alignment: .leading) {
                        // lowerHeader Text
                        HStack {
                            Text(lowerHeader)
                                .font(.body)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        HStack {
                            // lowerSubHeader Text
                            Text(lowerSubHeader)
                                .font(.body)
                            Spacer()
                        }
                    }
                    .frame(width: 550)

                    // Bottom buttons
                    HStack {
                        // actionButton
                        Button(action: Utils().updateDevice, label: {
                            Text(actionButtonText)
                          }
                        )
                        .keyboardShortcut(.defaultAction)
                        
                        // Separate the buttons with a spacer
                        Spacer()
                        
                        if Utils().demoModeEnabled() || !pastRequiredInstallationDate && allowedDeferrals > self.deferralCountUI {
                            // secondaryQuitButton
                            if requireDualQuitButtons {
                                if self.hasClickedSecondaryQuitButton {
                                    Button(action: {}, label: {
                                        Text(secondaryQuitButtonText)
                                      }
                                    )
                                    .hidden()
                                } else {
                                    Button(action: {
                                        hasClickedSecondaryQuitButton = true
                                    }, label: {
                                        Text(secondaryQuitButtonText)
                                      }
                                    )
                                }
                            } else {
                                Button(action: {}, label: {
                                    Text(secondaryQuitButtonText)
                                  }
                                )
                                .hidden()
                            }
                        
                            // primaryQuitButton
                            if requireDualQuitButtons {
                                if self.hasClickedSecondaryQuitButton {
                                    Button(action: {AppKit.NSApp.terminate(nil)}, label: {
                                        Text(primaryQuitButtonText)
                                            .frame(minWidth: 35)
                                      }
                                    )
                                } else {
                                    Button(action: {
                                        hasClickedSecondaryQuitButton = true
                                    }, label: {
                                        Text(primaryQuitButtonText)
                                            .frame(minWidth: 35)
                                      }
                                    )
                                    .hidden()
                                }
                            } else {
                                Button(action: {AppKit.NSApp.terminate(nil)}, label: {
                                    Text(primaryQuitButtonText)
                                        .frame(minWidth: 35)
                                  }
                                )
                            }
                        }
                    }
                    .frame(width: 550)
                }
                .frame(width: 600)
                .padding(.bottom, 15)
                // https://www.hackingwithswift.com/books/ios-swiftui/running-code-when-our-app-launches
                .onAppear(perform: nudgeStartLogic)
            }
            .frame(width: 900, height: 450)
        }
    }
}

// Sheet view for Screenshot zoom
struct screenShotZoom: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {self.presentationMode.wrappedValue.dismiss()}, label: {
            if colorScheme == .dark && FileManager.default.fileExists(atPath: screenShotDarkPath) {
                Image(nsImage: Utils().createImageData(fileImagePath: screenShotDarkPath))
                    .resizable().scaledToFit()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            } else if colorScheme == .light && FileManager.default.fileExists(atPath: screenShotLightPath) {
                Image(nsImage: Utils().createImageData(fileImagePath: screenShotLightPath))
                    .resizable().scaledToFit()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            } else {
                Image("CompanyScreenshotIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                    .frame(width: 512, height: 512)
            }
          }
        )
        .buttonStyle(PlainButtonStyle())
        .help("Click to close")
    }
}


#if DEBUG
// Xcode preview for both light and dark mode
struct Nudge_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Nudge().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
                .preferredColorScheme(.light)
            Nudge().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
                .preferredColorScheme(.dark)
            Nudge().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.2") ))
                .preferredColorScheme(.dark)
                .environment(\.locale, .init(identifier: "fr"))
        }
    }
}
#endif
