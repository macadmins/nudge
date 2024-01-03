//
//  CloseButton.swift
//  Nudge
//
//  Created by Erik Gomez on 1/3/24.
//

import Foundation
import SwiftUI

struct CloseButton: View {
    var body: some View {
        Image(systemName: "xmark.circle")
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundColor(.red)
    }
}
