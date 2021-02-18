import Foundation

// PolicyManager resolves the app state, separating the UI from external actions,
// like interacting with the user, the OS or other parts of the environment.

class PolicyManager: ObservableObject {
    @Published var current: OSVersion

    init() {
        self.current = OSVersion(ProcessInfo().operatingSystemVersion)
    }

    init(withVersion: OSVersion) {
        self.current = withVersion
    }
}

//class PolicyManager: ObservableObject {
//    let current: OSVersion
//    let allowedVersions: [OSVersionRequirement]
//
//    init() throws {
//        self.current = OSVersion(ProcessInfo().operatingSystemVersion)
//        self.defaults = .standard
//
//        guard
//            let versionsDict = defaults.object(forKey: "osVersionRequirement") as? [[String: Any]]
//        else {
//            throw DefaultsError.missingKey("osVersionRequirement")
//        }
//        self.allowedVersions = try versionsDict.map(OSVersionRequirement.init)
//    }
//
//    init(withVersion: OSVersion) {
//        self.current = withVersion
//        self.defaults = .standard // add something different for previews?
//        self.allowedVersions = []
//    }
//}
//
//enum DefaultsError: Error {
//    case missingKey(_ key: String)
//    case wrongKeyType(_ msg: String)
//}
//
//extension Dictionary where Key == String {
//    // helper that reads plist keys and converts them to the expected type.
//    // throws an error if the type is wrong or if the plist doesn't have the expected key.
//    func nudgeDefault<T>(_ key: String) throws -> T {
//        guard let _v = self[key] else {
//            throw DefaultsError.missingKey(key)
//        }
//
//        guard let value = _v as? T else {
//            throw DefaultsError.wrongKeyType("nudge defaults \(_v) is not \(T.self)")
//        }
//        return value
//    }
//}
