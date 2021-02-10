//
//  Nudge.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import Foundation
import SwiftUI

// Get the default filemanager
let fileManager = FileManager.default

// These are initial variables that nudge will update within the timer controller
// Perhaps they should be moved somewhere else, but will need to be rethought out.
var lastRefreshTime = Utils().returnInitialDate()
var afterFirstRun = false

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
    @State var daysRemaining = Utils().numberOfDaysBetween()
    @State var requireDualCloseButtons = Utils().requireDualCloseButtons()
    @State var pastRequiredInstallationDate = Utils().pastRequiredInstallationDate()
    @State var hasAcceptedIUnderstand = false
    @State var deferralCount = 0
    
    // Modal view for screenshot
    @State var showSSDetail = false
    
    // Get the screen frame
    var screen = NSScreen.main?.visibleFrame
    
    let nudgeRefreshCycleTimer = Timer.publish(every: Double(nudgeRefreshCycle), on: .main, in: .common).autoconnect()

    // Nudge UI
    var body: some View {
        HStack(spacing: 0){
            // Left side of Nudge
            VStack{
                // Company Logo
                if colorScheme == .dark {
                    if fileManager.fileExists(atPath: iconDarkPath) {
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
                    if fileManager.fileExists(atPath: iconLightPath) {
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

                    // Fully Updated
//                    HStack{
//                        Text("Fully Updated: ")
//                        Spacer()
//                        Text(String(fullyUpdated()).capitalized)
//                            .foregroundColor(.gray)
//                    }.padding(.vertical, 1.0)

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
                        Text(String(self.deferralCount))
                            .onReceive(nudgeRefreshCycleTimer) { _ in
                                if needToActivateNudge(deferralCount: self.deferralCount, lastRefreshTimeVar: lastRefreshTime) {
                                    self.deferralCount += 1
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
                        Button(action: Utils().moreInfo, label: {
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
                            if fileManager.fileExists(atPath: screenShotPath) {
                                Image(nsImage: Utils().createImageData(fileImagePath: screenShotPath))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding()
                                    .frame(width: 128, height: 128)
                            } else {
                                Image("CompanyScreenshotIcon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding()
                                    .frame(width: 128, height: 128)
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
                    
                    if Utils().inDemoMode() || !pastRequiredInstallationDate && allowedDeferrals > self.deferralCount {
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
    
    var body: some View {
        Button(action: {self.presentationMode.wrappedValue.dismiss()}, label: {
            if fileManager.fileExists(atPath: screenShotPath) {
                Image(nsImage: Utils().createImageData(fileImagePath: screenShotPath))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                    .frame(width: 512, height: 512)
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

// Start doing a basic check
func nudgeStartLogic() {
    if Utils().fullyUpdated() {
        // Because Nudge will bail if it detects installed OS >= required OS, this will cause the Xcode preview to fail.
        // https://zacwhite.com/2020/detecting-swiftui-previews/
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        } else {
            if Utils().inDemoMode() {
                print("Device in demo mode")
            } else {
                print("Device fully up-to-date.")
                AppKit.NSApp.terminate(nil)
            }
        }
    }
}

func needToActivateNudge(deferralCount: Int, lastRefreshTimeVar: Date) -> Bool {
    // If noTimers is true, just bail
    if noTimers {
        return false
    }
    
    let currentTime = Date().timeIntervalSince1970
    let timeDiff = Int((currentTime - lastRefreshTimeVar.timeIntervalSince1970))

    // The first time the main timer contoller hits we don't care
    if !afterFirstRun {
        _ = afterFirstRun = true
        _ = lastRefreshTime = Date()
        return false
    }
    
    // TODO: turn initialRefreshCycle into conditional
    if Utils().returnTimerController() > timeDiff  {
        return false
    }
    
    let frontmostApplication = NSWorkspace.shared.frontmostApplication
    
    // Don't nudge if major upgrade is frontmostApplication
    if fileManager.fileExists(atPath: majorUpgradeAppPath) {
        if NSURL.fileURL(withPath: majorUpgradeAppPath) == frontmostApplication?.bundleURL {
            print("Upgrade app is currently frontmostApplication")
            return false
        }
    }
    
    // Don't nudge if acceptable apps are frontmostApplication
    if acceptableApps.contains((frontmostApplication?.bundleIdentifier!)!) {
        print("An acceptable app is currently frontmostApplication")
        return false
    }
    
    // If we get here, Nudge if not frontmostApplication
    if !NSApplication.shared.isActive {
        _ = deferralCount + 1 // TODO: this needs to be rethought out. It's one integer behind
        _ = lastRefreshTime = Date()
        Utils().activateNudge()
        if deferralCount > allowedDeferrals  {
            print("Nudge deferral count over threshold")
            Utils().updateDevice()
        }
        return true
    }
    return false
}
