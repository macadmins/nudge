//
//  Extensions.swift
//  Nudge
//
//  Created by Erik Gomez on 6/13/23.
//

import Foundation
import SwiftUI

extension Color {
    static let accessibleBlue = Color(red: 26 / 255, green: 133 / 255, blue: 255 / 255)
    static let accessibleRed = Color(red: 230 / 255, green: 97 / 255, blue: 0 / 255)
    static let accessibleSecondaryLight = Color(red: 100 / 255, green: 100 / 255, blue: 100 / 255)
    static let accessibleSecondaryDark = Color(red: 150 / 255, green: 150 / 255, blue: 150 / 255)
}

extension Date {
    func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
}

extension FixedWidthInteger {
    // https://stackoverflow.com/a/63539782
    var byteWidth:Int {
        return self.bitWidth/UInt8.bitWidth
    }
    static var byteWidth:Int {
        return Self.bitWidth/UInt8.bitWidth
    }
}

// https://github.com/brackeen/calculate-widget/blob/master/Calculate/NSWindow%2BMoveToActiveSpace.swift#L64
extension NSWorkspace {
    func isActiveSpaceFullScreen() -> Bool {
        guard let winInfoArray = CGWindowListCopyWindowInfo([.excludeDesktopElements, .optionOnScreenOnly], kCGNullWindowID) as? Array<[String : Any]> else {
            return false
        }
        for winInfo in winInfoArray {
            guard let windowLayer = winInfo[kCGWindowLayer as String] as? NSNumber, windowLayer == 0 else {
                continue
            }
            guard let boundsDict = winInfo[kCGWindowBounds as String] as? [String : Any], let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else {
                continue
            }
            if bounds.size == NSScreen.main?.frame.size {
                return true
            }
        }
        return false
    }
}

extension Scene {
    func windowResizabilityContentSize() -> some Scene {
        if #available(macOS 13.0, *) {
            return windowResizability(.contentSize)
        } else {
            return self
        }
    }
}

// https://stackoverflow.com/questions/29985614/how-can-i-change-locale-programmatically-with-swift
// Apple recommends against this, but this is super frustrating since Nudge does dynamic UIs
extension String {
    func localized(desiredLanguage :String) ->String {
        // Try to get the language passed and if it does not exist, use en
        let path = bundle.path(forResource: desiredLanguage, ofType: "lproj") ?? bundle.path(forResource: "en", ofType: "lproj")
        let bundle = Bundle(path: path!)
        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }
}
