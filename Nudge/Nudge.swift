//
//  Nudge.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import SwiftUI

// All of this image stuff needs to be refactored.
// Setup Variables for light logo
let logo_light_url_path = NSURL(fileURLWithPath: "/Library/nudgeplayground/Resources/company_logo_light.png")
let logo_light_path = logo_light_url_path.path
let logo_light_data:NSData = NSData(contentsOf: logo_light_url_path as URL)!
let logo_light_image = NSImage(data: logo_light_data as Data)

// Setup Variables for dark logo
let logo_dark_url_path = NSURL(fileURLWithPath: "/Library/nudgeplayground/Resources/company_logo_dark.png")
let logo_dark_path = logo_dark_url_path.path
let logo_dark_data:NSData = NSData(contentsOf: logo_dark_url_path as URL)!
let logo_dark_image = NSImage(data: logo_dark_data as Data)

// Setup Variables for company screenshot
let company_screenshot_url_path = NSURL(fileURLWithPath: "/Library/nudgeplayground/Resources/company_screenshot.png")
let company_screenshot_path = company_screenshot_url_path.path
let company_screenshot_data:NSData = NSData(contentsOf: company_screenshot_url_path as URL)!
let company_screenshot_image = NSImage(data: company_screenshot_data as Data)

// Get the default filemanager
let fileManager = FileManager.default

struct Nudge: View {
    // Get the color scheme so we can dynamically change properties
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL

    // Get the screen frame
    var screen = NSScreen.main?.visibleFrame

    // Hardcoded (for now) properties
    @State var user_name = "erikg"
    @State var serial_number = "C00000000000"
    @State var fully_updated = "No"
    @State var days_remaining = "14"
    @State var deferral_count = "0"
    @State var has_accepted_i_understand = false

    // Nudge UI
    var body: some View {
        HStack(spacing: 0){
            // Left side of Nudge
            VStack{
                // Company Logo
                if colorScheme == .dark {
                    if fileManager.fileExists(atPath: logo_dark_path!) {
                        Image(nsImage: logo_dark_image!)
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
                    if fileManager.fileExists(atPath: logo_light_path!) {
                        Image(nsImage: logo_light_image!)
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
                    Text(self.fully_updated)
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
                    Text(self.deferral_count)
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
                    Text("macOS Update")
                        .font(.largeTitle)
                }
                .padding(.top, 10.0)
                .padding(.bottom, 20.0)
                .padding(.leading, 15.0)

                // Subtitle Text
                HStack{
                    Text("A friendly reminder from your local IT team")
                        .font(.body)
                }
                .padding(.vertical, 0.5)
                .padding(.leading, 15.0)

                // Update Text
                HStack{
                    Text("A security update is required on your machine.")
                        .font(.body)
                        .fontWeight(.bold)
                }
                .padding(.vertical, 0.5)
                .padding(.leading, 15.0)

                VStack(alignment: .leading) {
                    // Paragraph 1
                    Text("A fully up-to-date device is required to ensure that IT can your accurately protect your computer.")
                        .font(.body)
                        .fontWeight(.regular)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 5.0)
                // Paragraph 2
                    Text("If you do not update your computer, you may lose access to some items necessary for your day-to-day tasks.")
                        .font(.body)
                        .fontWeight(.regular)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 5.0)
                // Paragraph 3
                    Text("To begin the update, simply click on the button below and follow the provided steps.")
                        .font(.body)
                        .fontWeight(.regular)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                // Company Screenshot
                    HStack{
                        Spacer()
                        if fileManager.fileExists(atPath: company_screenshot_path!) {
                            Image(nsImage: company_screenshot_image!)
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
                        Spacer()
                        }
                }
                .padding(.vertical,10.0)
                .padding(.leading, 15.0)
                .frame(width: 520)

                // Force buttons to the bottom with a spacer
                Spacer()

                // Bottom buttons
                HStack(alignment: .top){
                    Button(action: {}, label: {
                        Text("Update Machine")
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
                .padding(.leading, 15.0)
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


struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Nudge()
    }
}
