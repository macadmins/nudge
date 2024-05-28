//
//  OSVersion.swift
//  Nudge
//
//  Created by Erik Gomez on 2/8/21.
//

import Foundation

// Version of a macOS release. Example: 11.2
public struct OSVersion {
    public var major: Int
    public var minor: Int
    public var patch: Int

    /// Errors that can occur when parsing a version string.
    public enum ParseError: Error {
        case badFormat(reason: String)
    }

    /// Creates an `OSVersion` by providing all the parts.
    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// Creates an `OSVersion` by converting the built-in `OperatingSystemVersion`.
    public init(_ version: OperatingSystemVersion) {
        self.major = version.majorVersion
        self.minor = version.minorVersion
        self.patch = version.patchVersion
    }

    /// Creates an `OSVersion` by parsing a string like "11.2".
    public init(_ string: String) throws {
        let parts = string.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 2 || parts.count == 3 else {
            let error = "Input \(string) must have 2 or 3 parts, got \(parts.count)."
            LogManager.error(error, logger: utilsLog)
            throw ParseError.badFormat(reason: error)
        }

        guard let major = Int(parts[0]), let minor = Int(parts[1]) else {
            let error = "Invalid format for major or minor version in \(string)."
            LogManager.error(error, logger: utilsLog)
            throw ParseError.badFormat(reason: error)
        }
        let patch = parts.count >= 3 ? Int(parts[2]) ?? 0 : 0

        self.init(major: major, minor: minor, patch: patch)
    }
}

extension OSVersion: CustomStringConvertible {
    public var description: String {
        "\(major).\(minor)\(patch > 0 ? ".\(patch)" : "")"
    }
}

extension OSVersion: Equatable, Comparable {
    public static func == (lhs: OSVersion, rhs: OSVersion) -> Bool {
        return (lhs.major, lhs.minor, lhs.patch) == (rhs.major, rhs.minor, rhs.patch)
    }

    public static func < (lhs: OSVersion, rhs: OSVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}
