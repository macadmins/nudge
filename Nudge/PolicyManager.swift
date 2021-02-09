import Foundation

// PolicyManager resolves the app state, separating the UI from external actions,
// like interacting with the user, the OS or other parts of the environment.
class PolicyManager: ObservableObject {
    let current: OSVersion
    let defaults: UserDefaults
    let allowedVersions: [OSVersionRequirement]
    
    init() throws {
        self.current = OSVersion(ProcessInfo().operatingSystemVersion)
        self.defaults = .standard
        
        guard
            let versionsDict = defaults.object(forKey: "osVersionRequirement") as? [[String: Any]]
        else {
            throw DefaultsError.missingKey("osVersionRequirement")
        }
        self.allowedVersions = try versionsDict.map(OSVersionRequirement.init)
    }
    
    init(withVersion: OSVersion) {
        self.current = withVersion
        self.defaults = .standard // add something different for previews?
        self.allowedVersions = []
    }
    
    func evaluateStatus() throws -> Status {
       guard
        let best = allowedVersions.max(by: {
            if $0.requiredMinimumOSVersion.major != $1.requiredMinimumOSVersion.major {
                return $0.requiredMinimumOSVersion.major < $1.requiredMinimumOSVersion.major
            }
            return $0.requiredMinimumOSVersion.minor < $1.requiredMinimumOSVersion.minor
        })
       else {
        throw NudgeError.noMatchingRequiredVersion
       }
        
        if current >= best.requiredMinimumOSVersion {
            return .noUpdateRequired
        }
        
        if best.requiredMinimumOSVersion.major == current.major {
            return .minorUpdate(version: best)
        }
        return .majorUpgrade(version: best)
    }
    

    
    enum Status {
        case noUpdateRequired
        case minorUpdate(version: OSVersionRequirement)
        case majorUpgrade(version: OSVersionRequirement)
    }
}

enum NudgeError: Error {
    case noMatchingRequiredVersion
}

enum DefaultsError: Error {
    case missingKey(_ key: String)
    case wrongKeyType(_ msg: String)
}

extension Dictionary where Key == String {
    // helper that reads plist keys and converts them to the expected type.
    // throws an error if the type is wrong or if the plist doesn't have the expected key.
    func nudgeDefault<T>(_ key: String) throws -> T {
        guard let _v = self[key] else {
            throw DefaultsError.missingKey(key)
        }
        
        guard let value = _v as? T else {
            throw DefaultsError.wrongKeyType("nudge defaults \(_v) is not \(T.self)")
        }
        return value
    }
}
