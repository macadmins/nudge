import Foundation

// Version of a macOS release. Example: 11.2
public struct OSVersion {
    public var major: Int
    public var minor: Int
    public var patch: Int
    
    public enum ParseError: Error {
        case badFormat(_ reason: String)
    }
    
    // Creates an OSVersion by providing all the parts.
    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    // Creates an OSVersion by converting the built-in OperatingSystemVersion.
    public init(_ version: OperatingSystemVersion) {
        self.major = version.majorVersion
        self.minor = version.minorVersion
        self.patch = version.patchVersion
    }
    
    // Creates an OSVersion by parsing a string like "11.2".
    public init(_ string: String) throws {
        let parts = string.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 2 || parts.count == 3 else {
            throw ParseError.badFormat("Input \(string) must have either 2 or 3 parts, got \(parts.count).")
        }
        
        guard
            let major = Int(parts[0]),
            let minor = Int(parts[1]),
            let patch: Int = parts.count >= 3 ? Int(parts[2]) : 0 // optional, default to zero if missing.
        else {
            throw ParseError.badFormat("Converting string parts to Int")
        }
        self.init(major: major, minor: minor, patch: patch)
    }
}

extension OSVersion: CustomStringConvertible {
    public var description: String {
        if patch == 0 {
            return "\(major).\(minor)"
        } else {
            return "\(major).\(minor).\(patch)"
        }
    }
}

extension OSVersion: Equatable {
    public static func == (lhs: OSVersion, rhs: OSVersion) -> Bool {
        return (lhs.major, lhs.minor, lhs.patch) == (rhs.major, rhs.minor, rhs.patch)
    }
}

extension OSVersion: Comparable {
    public static func < (lhs: OSVersion, rhs: OSVersion) -> Bool {
        return (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}
