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
    @State var requireDualCloseButtons = Utils().requireDualCloseButtons()
    @State var pastRequiredInstallationDate = Utils().pastRequiredInstallationDate()
    @State var hasAcceptedIUnderstand = false
    @State var deferralCountUI = 0
    
    // Modal view for screenshot
    @State var showSSDetail = false
    
    // Get the screen frame
    var screen = NSScreen.main?.visibleFrame
    
    // Setup the main refresh timer that controls the child refresh logic
    let nudgeRefreshCycleTimer = Timer.publish(every: Double(nudgeRefreshCycle), on: .main, in: .common).autoconnect()

    // Nudge UI
    var body: some View {
        HStack(spacing: 0){
            // Left side of Nudge
            VStack{
                // Company Logo
                if colorScheme == .dark {
                    if FileManager.default.fileExists(atPath: iconDarkPath) {
                        Image(nsImage: Utils().createImageData(fileImagePath: iconDarkPath))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 128, height: 128)
                    } else {
                        Image(systemName: "applelogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 128, height: 128)
                            .padding(.bottom, 10.0)
                    }
                } else {
                    if FileManager.default.fileExists(atPath: iconLightPath) {
                        Image(nsImage: Utils().createImageData(fileImagePath: iconLightPath))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 128, height: 128)
                    } else {
                        Image(systemName: "applelogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 128, height: 128)
                            .padding(.bottom, 10.0)
                    }
                }

                // Horizontal line
                HStack{
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(height: 1)
                }
                .frame(width:215)
                
                // Can only have 10 objects per stack unless you hack it and use groups
                Group {
                    // Required OS Version
                    HStack{
                        Text("Required OS Version: ")
                            .fontWeight(.bold)
                        Spacer()
                        Text(String(requiredMinimumOSVersion).capitalized)
                            .foregroundColor(.gray)
                            .fontWeight(.bold)
                    }.padding(.vertical, 1.0)
                    
                    // Current OS Version
                    HStack{
                        Text("Current OS Version: ")
                        Spacer()
                        Text(manager.current.description)
                            .foregroundColor(.gray)
                    }.padding(.vertical, 1.0)
                    
                    // Username
                    HStack{
                        Text("Username: ")
                        Spacer()
                        Text(self.systemConsoleUsername)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 1.0)

                    // Serial Number
                    HStack{
                        Text("Serial Number: ")
                        Spacer()
                        Text(self.serialNumber)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 1.0)

                    // Architecture
                    HStack{
                        Text("Architecture: ")
                        Spacer()
                        Text(self.cpuType)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 1.0)

                    // Days Remaining
                    HStack{
                        Text("Days Remaining: ")
                        Spacer()
                        if self.daysRemaining <= 0 {
                            Text(String(0))
                                .foregroundColor(.gray)
                        } else {
                            Text(String(self.daysRemaining))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 1.0)

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
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20.0)

                // Force buttons to the bottom with a spacer
                Spacer()

                // More Info
                // https://developer.apple.com/documentation/swiftui/openurlaction
                HStack(alignment: .top) {
                    if informationButtonPath != "" {
                        Button(action: Utils().openMoreInfo, label: {
                            Text("More Info")
                          }
                        )
                    }
                    // Force the button to the left with a spacer
                    Spacer()
                }
            }
            .padding(.bottom, 7.5)
            .padding(.leading, -20.0)
            .frame(width: 300, height: 450)
            
            // Vertical Line
            VStack{
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 1)
            }
            .frame(height: 300)

            // Right side of Nudge
            VStack{
                // mainHeader Text
                HStack{
                    Text(mainHeader)
                        .font(.largeTitle)
                }
                .padding(.top, 5.0)
                .padding(.leading, 15.0)

                // subHeader Text
                HStack{
                    Text(subHeader)
                        .font(.body)
                }
                .padding(.vertical, 0.5)
                .padding(.leading, 15.0)

                // mainContent Header
                HStack{
                    Text(mainContentHeader)
                        .font(.body)
                        .fontWeight(.bold)
                }
                .padding(.vertical, 0.5)
                .padding(.leading, 15.0)

                VStack(alignment: .leading) {
                    // mainContent Text
                    Text(mainContentText)
                        .font(.body)
                        .fontWeight(.regular)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 5.0)

                // Company Screenshot
                    HStack{
                        Spacer()
                        Group{
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
                                    .resizable().scaledToFit()
                                    .aspectRatio(contentMode: .fit)
                                    .padding()
                            }
                            Button(action: {
                                self.showSSDetail.toggle()
                            }) {
                                Image(systemName: "plus.magnifyingglass")
                            }
                            .padding(.leading, -15.0)
                            .sheet(isPresented: $showSSDetail) {
                                screenShotZoom()
                            }
                            .help("Click to zoom into screenshot")
                        }
                        Spacer()
                    }
                }
                .padding(.vertical, 1.0)
                .padding(.leading, 15.0)
                .frame(width: 520)

                // Force buttons to the bottom with a spacer
                Spacer()
                VStack(alignment: .leading) {
                    // lowerHeader Text
                    Text(lowerHeader)
                        .font(.body)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    // lowerSubHeader Text
                    Text(lowerSubHeader)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.leading, 15.0)
                .frame(width: 520)

                // Bottom buttons
                HStack(alignment: .top){
                    // Update Device button
                    Button(action: Utils().updateDevice, label: {
                        Text("Update Device")
                      }
                    )
                    
                    // Separate the buttons with a spacer
                    Spacer()
                    
                    if Utils().demoModeEnabled() || !pastRequiredInstallationDate && allowedDeferrals > self.deferralCountUI {
                        // I understand button
                        if requireDualCloseButtons {
                            if self.hasAcceptedIUnderstand {
                                Button(action: {}, label: {
                                    Text("I understand")
                                  }
                                )
                                .hidden()
                                .padding(.trailing, 10.0)
                            } else {
                                Button(action: {
                                    hasAcceptedIUnderstand = true
                                }, label: {
                                    Text("I understand")
                                  }
                                )
                                .padding(.trailing, 10.0)
                            }
                        } else {
                            Button(action: {}, label: {
                                Text("I understand")
                              }
                            )
                            .hidden()
                            .padding(.trailing, 10.0)
                        }
                    
                        // OK button
                        if requireDualCloseButtons {
                            if self.hasAcceptedIUnderstand {
                                Button(action: {AppKit.NSApp.terminate(nil)}, label: {
                                    Text("OK")
                                        .frame(minWidth: 35.0)
                                  }
                                )
                            } else {
                                Button(action: {
                                    hasAcceptedIUnderstand = true
                                }, label: {
                                    Text("OK")
                                        .frame(minWidth: 35.0)
                                  }
                                )
                                .hidden()
                            }
                        } else {
                            Button(action: {AppKit.NSApp.terminate(nil)}, label: {
                                Text("OK")
                                    .frame(minWidth: 35.0)
                              }
                            )
                        }
                    }
                }
                .padding(.leading, 25.0)
                .padding(.trailing, -20.0)
            }
            .frame(width: 550, height: 450)
            .padding(.bottom, 15.0)
            // https://www.hackingwithswift.com/books/ios-swiftui/running-code-when-our-app-launches
            .onAppear(perform: nudgeStartLogic)
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
            Nudge().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.1") ))
                .preferredColorScheme(.light)
            Nudge().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.1") ))
                .preferredColorScheme(.dark)
            Nudge().environmentObject(PolicyManager(withVersion:  try! OSVersion("11.1") ))
                .preferredColorScheme(.dark)
                .environment(\.locale, .init(identifier: "fr"))
        }
    }
}
#endif
