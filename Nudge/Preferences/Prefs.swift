import Foundation

class Preferences {

  internal let defaults: UserDefaults
  internal let requirements: [OSVersionRequirement]
  internal let defaultJSONSrc = "file:///Library/Preferences/com.github.macadmins.Nudge.json"
  let systemVersion: OSVersion

  init(
    defaults: UserDefaults = .standard,
    systemVersion: OSVersion = OSVersion(ProcessInfo.processInfo.operatingSystemVersion)
  ) {
    self.defaults = defaults
    self.systemVersion = systemVersion

    switch config(self.defaults.string(forKey: "json-url") ?? defaultJSONSrc) {
    case .userDefaults:
      guard
        let
          // or String: Any ?
          rs = defaults.object(forKey: "osVersionRequirements") as? [[String: AnyObject]]
      else {

        // TODO: throw
        self.requirements = [OSVersionRequirement]()
        return
      }

      self.requirements = rs.map(OSVersionRequirement.init)

    // TODO: Handle JSON requirements... I think I'll need to further refactor this so the json case gets the whole NudgePrefences first.
    case .jsonWeb:
      self.requirements = [OSVersionRequirement]()

    case .jsonFile:
      self.requirements = [OSVersionRequirement]()
    }

  }

  func targetVersion() -> OSVersionRequirement {
    var fullMatch = OSVersionRequirement()
    var partialMatch = OSVersionRequirement()
    var defaultMatch = OSVersionRequirement()

    requirements.enumerated().forEach { k, v in
      guard let target = v.targetedOSVersionsRule else {
        defaultMatch = v
        return
      }

      if target == "default" {
        defaultMatch = v
        return
      }

      guard let tv = try? OSVersion(target) else {
        // TODO handle this error, if we got this far, it's definitely a bug
        // This is annoying because targetOSVersionRule is a optional string instead of a OSVersionRequirement
        return
      }

      if tv == systemVersion {
        // this feels awkward. We are returning a requirement not checking for whether we need to act on it.
        // is full match necessary?
        //
        // instead of returning a match, we can return an enum with .noUpdateRequired and updateTo(OSVersionRequirement)
        // The enum would be great because it would also let us define some states like imminent/gracePeriod etc
        fullMatch = v
        return
      }

      if tv.major == systemVersion.major {
        partialMatch = v
        return
      }
    }

    if fullMatch.requiredMinimumOSVersion != nil {
      return fullMatch
    } else if partialMatch.requiredMinimumOSVersion != nil {
      return partialMatch
    } else if defaultMatch.requiredMinimumOSVersion != nil {
      return defaultMatch
    }

    return OSVersionRequirement()
    // TODO: set the default values here? I'd prefer to throw if we didn't find a match,
    // deal with defaults for url/path/button config separately.
  }

  public var nudgeVersion: String {
    return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
  }
}

enum preferenceSource {
  case jsonFile
  case jsonWeb
  case userDefaults
}

private func config(_ url: String) -> preferenceSource {
  if url.contains("https://") || url.contains("http://") {
    return .jsonWeb
  }
  if url.starts(with: "file:///") && FileManager.default.fileExists(atPath: url) {
    return .jsonFile
  }
  return .userDefaults
}
