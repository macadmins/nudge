//
//  Nudge.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import SwiftUI
import SystemConfiguration

// Prefs
let nudge_prefs = nudgePrefs().loadNudgePrefs()

// Setup Variables for light logo
let logo_light_path = nudge_prefs?.logo_light_path ?? "/Library/nudge/Resources/company_logo_light.png"
let logo_light_image = createImageData(fileImagePath: logo_light_path)

// Setup Variables for dark logo
let logo_dark_path = nudge_prefs?.logo_dark_path ?? "/Library/nudge/Resources/company_logo_dark.png"
let logo_dark_image = createImageData(fileImagePath: logo_dark_path)

// Setup Variables for company screenshot
// TODO: Call icns from the system rather than bring in a png as an asset for default
let company_screenshot_path = nudge_prefs?.screenshot_path ?? "/Library/nudge/Resources/company_screenshot.png"
let company_screenshot_image = createImageData(fileImagePath: company_screenshot_path)

// Get the default filemanager
let fileManager = FileManager.default

// Primary Nudge UI
struct Nudge: View {
    // Get the color scheme so we can dynamically change properties
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL

    // Get the screen frame
    var screen = NSScreen.main?.visibleFrame

    // Hardcoded (for now) properties
    @State var user_name = getSystemConsoleUsername()
    @State var serial_number = getSerialNumber()
    @State var days_remaining = ""
    @State var deferral_count = 0
    @State var has_accepted_i_understand = false
    
    // Modal view for screenshot
    @State var showSSDetail = false

    // Nudge UI
    var body: some View {
        HStack(spacing: 0){
            // Left side of Nudge

            VStack{
                // Company Logo
                if colorScheme == .dark {
                    if fileManager.fileExists(atPath: logo_dark_path) {
                        Image(nsImage: logo_dark_image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                            .frame(width: 160, height: 160)
                            .padding(.vertical, 1.0)
                    } else {
                        Image(systemName: "applelogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                            .frame(width: 160, height: 160)
                            .padding(.vertical, 1.0)
                    }
                } else {
                    if fileManager.fileExists(atPath: logo_light_path) {
                        Image(nsImage: logo_light_image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                            .frame(width: 160, height: 160)
                            .padding(.vertical, 1.0)
                    } else {
                        Image(systemName: "applelogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                            .frame(width: 160, height: 160)
                            .padding(.vertical, 1.0)
                    }
                }

                // Horizontal line
                HStack{
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(height: 1)
                }
                .frame(width:215)

                // Username
                HStack{
                    Text("Username: ")
                    Spacer()
                    Text(self.user_name)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 1.0)

                // Serial Number
                HStack{
                    Text("Serial Number: ")
                    Spacer()
                    Text(self.serial_number)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 1.0)

                // Fully Updated
                HStack{
                    Text("Fully Updated: ")
                    Spacer()
                    Text("No")
                        .foregroundColor(.gray)
                }

                // Days Remaining
                HStack{
                    Text("Days Remaining: ")
                    Spacer()
                    Text(self.days_remaining)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 1.0)

                // Deferral Count
                HStack{
                    Text("Deferral Count: ")
                    Spacer()
                    Text(String(self.deferral_count))
                        .foregroundColor(.gray)
                }

                // Force buttons to the bottom with a spacer
                Spacer()

                // More Info
                // https://developer.apple.com/documentation/swiftui/openurlaction
                HStack(alignment: .top){
                    Button(action: moreInfo, label: {
                        Text("More Info")
                      }
                    )
                    // Force the button to the left with a spacer
                    Spacer()
                }
                .padding(.bottom, 15.0)
            }
            .padding(.horizontal, 50)
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
                // Title Text
                HStack{
                    Text(nudge_prefs?.main_title_text ?? "macOS Update")
                        .font(.largeTitle)
                }
                .padding(.top, 5.0)
                .padding(.leading, 15.0)

                // Subtitle Text
                HStack{
                    Text(nudge_prefs?.main_subtitle_text ?? "A friendly reminder from your local IT team")
                        .font(.body)
                }
                .padding(.vertical, 0.5)
                .padding(.leading, 15.0)

                // Update Text
                HStack{
                    Text(nudge_prefs?.paragraph_title_text ?? "A security update is required on your device.")
                        .font(.body)
                        .fontWeight(.bold)
                }
                .padding(.vertical, 0.5)
                .padding(.leading, 15.0)

                VStack(alignment: .leading) {
                    // Paragraph
                    Text(nudge_prefs?.paragraph_text ?? "A fully up-to-date device is required to ensure that IT can your accurately protect your device. \n\nIf you do not update your device, you may lose access to some items necessary for your day-to-day tasks. \n\nTo begin the update, simply click on the button below and follow the provided steps.")
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
                            if fileManager.fileExists(atPath: company_screenshot_path) {
                                Image(nsImage: company_screenshot_image)
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
                            }.sheet(isPresented: $showSSDetail) {
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
                    Text(nudge_prefs?.button_title_text ?? "Ready to start the update?")
                        .font(.body)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(nudge_prefs?.button_sub_titletext ?? "Click on the button below.")
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.leading, 15.0)
                .frame(width: 520)

                // Bottom buttons
                HStack(alignment: .top){
                    // Update Device button
                    Button(action: updateDevice, label: {
                        Text("Update Device")
                      }
                    )

                    // Separate the buttons with a spacer
                    Spacer()
                    
                    // I understand button
                    if self.has_accepted_i_understand {
                        Button(action: {}, label: {
                            Text("I understand")
                          }
                        )
                        .hidden()
                        .padding(.trailing, 10.0)
                    } else {
                        Button(action: {
                            has_accepted_i_understand = true
                        }, label: {
                            Text("I understand")
                          }
                        )
                        .padding(.trailing, 10.0)
                    }
                    
                    // OK button
                    if self.has_accepted_i_understand {
                        Button(action: {exit(0)}, label: {
                            Text("OK")
                          }
                        )
                        .padding(.trailing, 20.0)
                    } else {
                        Button(action: {
                            has_accepted_i_understand = true
                        }, label: {
                            Text("OK")
                          }
                        )
                        .hidden()
                        .padding(.trailing, 20.0)
                    }
                }
                .padding(.bottom, 15.0)
                .padding(.leading, 25.0)
            }
            .frame(width: 550, height: 450)
        }
    }

    func moreInfo() {
        guard let url = URL(string: "https://www.google.com") else {
            return
        }
        openURL(url)
    }
}

// Sheet view for Screenshot zoom
struct screenShotZoom: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Button(action: {self.presentationMode.wrappedValue.dismiss()}, label: {
            if fileManager.fileExists(atPath: company_screenshot_path) {
                Image(nsImage: company_screenshot_image)
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

// Xcode preview for both light and dark mode
struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Nudge()
                .preferredColorScheme(.light)
            Nudge()
                .preferredColorScheme(.dark)
        }
    }
}

// Functions
func createImageData(fileImagePath: String) -> NSImage {
    let urlPath = NSURL(fileURLWithPath: fileImagePath)
    let imageData:NSData = NSData(contentsOf: urlPath as URL)!
    return NSImage(data: imageData as Data)!
}

func updateDevice() {
    NSWorkspace.shared.open(URL(fileURLWithPath: nudge_prefs?.path_to_app ?? "/Applications/Install macOS Big Sur.app"))
    // NSWorkspace.shared.open(URL(fileURLWithPath: "x-apple.systempreferences:com.apple.preferences.softwareupdate?client=softwareupdateapp"))
    // NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/SoftwareUpdate.prefPane"))
}

// https://gist.github.com/joncardasis/2c46c062f8450b96bb1e571950b26bf7
func getSystemConsoleUsername() -> String {
    var uid: uid_t = 0
    var gid: gid_t = 0
    return SCDynamicStoreCopyConsoleUser(nil, &uid, &gid) as String? ?? ""
}

// https://ourcodeworld.com/articles/read/1113/how-to-retrieve-the-serial-number-of-a-mac-with-swift
func getSerialNumber() -> String {
    var serialNumber: String? {
        let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice") )
        
        guard platformExpert > 0 else {
            return nil
        }
        
        guard let serialNumber = (IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeUnretainedValue() as? String)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
            return nil
        }
        
        IOObjectRelease(platformExpert)

        return serialNumber
    }
    
    return serialNumber ?? ""
}
