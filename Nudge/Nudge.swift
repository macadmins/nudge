//
//  Nudge.swift
//  Nudge
//
//  Created by Erik Gomez on 2/2/21.
//

import SwiftUI

struct Nudge: View {
    
    // getting screen Frame...
    var screen = NSScreen.main?.visibleFrame
    
    // TextFields...
    @State var user_name = "erikg"
    @State var serial_number = "C00000000000"
    @State var fully_updated = "No"
    @State var days_remaining = "14"
    @State var deferral_count = "0"
    @State var email = ""
    @State var password = ""
    // Keep Logged
    @State var keepLogged = false

    
    // Alert..
    @State var alert = false
    
    var body: some View {
        HStack(spacing: 0){
            // Left side of Nudge
            VStack{
                // Company Logo
                Image("company_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                    .frame(width: 160, height: 160)
                    .padding(.vertical, 1.0)

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
                        .foregroundColor(.black)
                    Spacer()
                    Text(self.user_name)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 1.0)
                
                // Serial Number
                HStack{
                    Text("Serial Number: ")
                        .foregroundColor(.black)
                    Spacer()
                    Text(self.serial_number)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 1.0)
                
                // Fully Updated
                HStack{
                    Text("Fully Updated: ")
                        .foregroundColor(.black)
                    Spacer()
                    Text(self.fully_updated)
                        .foregroundColor(.gray)
                }
                
                // Days Remaining
                HStack{
                    Text("Days Remaining: ")
                        .foregroundColor(.black)
                    Spacer()
                    Text(self.days_remaining)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 1.0)
                
                // Deferral Count
                HStack{
                    Text("Deferral Count: ")
                        .foregroundColor(.black)
                    Spacer()
                    Text(self.deferral_count)
                        .foregroundColor(.gray)
                }
                
                // Force buttons to the bottom with a spacer
                Spacer()
                
                // More Info
                HStack(alignment: .top){
                    Button(action: {}, label: {
                        Text("More Info")
                        .foregroundColor(.black)
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
                        .foregroundColor(.black)
                }
                .padding(.top, 10.0)
                .padding(.bottom, 20.0)
                .padding(.leading, 15.0)
                
                // Subtitle Text
                HStack{
                    Text("A friendly reminder from your local IT team")
                        .font(.body)
                        .foregroundColor(.black)
                }
                .padding(.vertical, 0.5)
                .padding(.leading, 15.0)
                
                // Update Text
                HStack{
                    Text("A security update is required on your machine.")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                .padding(.vertical, 0.5)
                .padding(.leading, 15.0)
                
                VStack(alignment: .leading) {
                    // Paragraph 1
                    Text("A fully up-to-date device is required to ensure that IT can your accurately protect your computer.")
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 5.0)
                // Paragraph 2
                    Text("If you do not update your computer, you may lose access to some items necessary for your day-to-day tasks.")
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 5.0)
                // Paragraph 3
                    Text("To begin the update, simply click on the button below and follow the provided steps.")
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
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
                        .foregroundColor(.black)
                      }
                    )
                    
                    // Separate the buttons with a spacer
                    Spacer()
                    Button(action: {}, label: {
                        Text("I understand")
                        .foregroundColor(.black)
                      }
                    )
                    .padding(.trailing, 10.0)
                    Button(action: {}, label: {
                        Text("OK")
                        .foregroundColor(.black)
                      }
                    )
                    .padding(.trailing, 20.0)
                }
                .padding(.bottom, 15.0)
                .padding(.leading, 15.0)
            }
            .frame(width: 550, height: 450)
        }
    }
}

struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Nudge()
    }
}
