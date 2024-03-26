//
//  Extensions.swift
//  Nudge
//
//  Created by Erik Gomez on 6/13/23.
//

import Foundation
import SwiftUI

// Color Extension
extension Color {
    static let accessibleBlue = Color(red: 26 / 255, green: 133 / 255, blue: 255 / 255)
    static let accessibleRed = Color(red: 230 / 255, green: 97 / 255, blue: 0)
    static let accessibleSecondaryLight = Color(red: 100 / 255, green: 100 / 255, blue: 100 / 255)
    static let accessibleSecondaryDark = Color(red: 150 / 255, green: 150 / 255, blue: 150 / 255)
}

// Date Extension
extension Date {
    private static var dateFormatter = DateFormatter()  // Reuse DateFormatter

    func getFormattedDate(format: String) -> String {
        Date.dateFormatter.dateFormat = format
        return Date.dateFormatter.string(from: self)
    }
}

// FixedWidthInteger Extension
extension FixedWidthInteger {
    // https://stackoverflow.com/a/63539782
    /// Calculates the number of bytes used to represent the integer.
    var byteWidth: Int {
        return self.bitWidth / UInt8.bitWidth
    }

    /// Static property to calculate the byte width of the integer type.
    static var byteWidth: Int {
        return Self.bitWidth / UInt8.bitWidth
    }
}

// Image Extension
extension Image {
    func customResizable(width: CGFloat? = nil, height: CGFloat? = nil, minHeight: CGFloat? = nil, minWidth: CGFloat? = nil, maxHeight: CGFloat? = nil, maxWidth: CGFloat? = nil) -> some View {
        self
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height, alignment: .center)
            .frame(minWidth: minWidth, maxWidth: maxWidth, minHeight: minHeight, maxHeight: maxHeight)
    }
}

extension View {
    @ViewBuilder
    func customFontWeight(fontWeight: Font.Weight? = nil) -> some View {
        if #available(macOS 13.0, *), let weight = fontWeight {
            self.fontWeight(weight)
        } else {
            self
        }
    }
}

// NSWorkspace Extension
// Originally from // https://github.com/brackeen/calculate-widget/blob/master/Calculate/NSWindow%2BMoveToActiveSpace.swift#L64
extension NSWorkspace {
    func isActiveSpaceFullScreen() -> Bool {
        guard let winInfoArray = CGWindowListCopyWindowInfo([.excludeDesktopElements, .optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        for winInfo in winInfoArray {
            guard let windowLayer = winInfo[kCGWindowLayer as String] as? NSNumber, windowLayer == 0,
                  let boundsDict = winInfo[kCGWindowBounds as String] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary),
                  bounds.size == NSScreen.main?.frame.size else {
                continue
            }
            return true
        }
        return false
    }
}

// Scene Extension
extension Scene {
    func windowResizabilityContentSize() -> some Scene {
        // No changes needed, well implemented for macOS 13.0+
        if #available(macOS 13.0, *) {
            return windowResizability(.contentSize)
        } else {
            return self
        }
    }
}

// Localization Extension
extension String {
    func localized(desiredLanguage: String) -> String {
        // https://stackoverflow.com/questions/29985614/how-can-i-change-locale-programmatically-with-swift
        // Apple recommends against this, but this is super frustrating since Nudge does dynamic UIs
        let path = Bundle.main.path(forResource: desiredLanguage, ofType: "lproj") ??
        Bundle.main.path(forResource: "en", ofType: "lproj")  // Fallback to English

        guard let bundle = (path != nil) ? Bundle(path: path!) : nil else {
            return self  // If both desired and fallback fail, return the original string
        }

        return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
    }
}

// View Extension
extension View {
    func onHoverEffect() -> some View {
        self.onHover { inside in
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
