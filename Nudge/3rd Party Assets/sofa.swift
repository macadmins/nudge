//
//  sofa.swift
//  Nudge
//
//  Created by Erik Gomez on 5/13/24.
//

import Foundation

struct MacOSDataFeed: Codable {
    let updateHash: String
    let osVersions: [SofaOSVersion]
    let xProtectPayloads: XProtectPayloads
    let xProtectPlistConfigData: XProtectPlistConfigData
    let models: [String: ModelInfo]
    let installationApps: InstallationApps

    enum CodingKeys: String, CodingKey {
        case updateHash = "UpdateHash"
        case osVersions = "OSVersions"
        case xProtectPayloads = "XProtectPayloads"
        case xProtectPlistConfigData = "XProtectPlistConfigData"
        case models = "Models"
        case installationApps = "InstallationApps"
    }
}

struct SofaOSVersion: Codable {
    let osVersion: String
    let latest: LatestOS
    let securityReleases: [SecurityRelease]
    let supportedModels: [SupportedModel]

    enum CodingKeys: String, CodingKey {
        case osVersion = "OSVersion"
        case latest = "Latest"
        case securityReleases = "SecurityReleases"
        case supportedModels = "SupportedModels"
    }
}

struct LatestOS: Codable {
    let productVersion, build: String
    let releaseDate: Date?
    let expirationDate: Date
    let supportedDevices: [String]

    enum CodingKeys: String, CodingKey {
        case productVersion = "ProductVersion"
        case build = "Build"
        case releaseDate = "ReleaseDate"
        case expirationDate = "ExpirationDate"
        case supportedDevices = "SupportedDevices"
    }
}

struct SecurityRelease: Codable {
    let updateName, productVersion: String
    let releaseDate: Date
    let securityInfo: String
    let supportedDevices: [String]
    let cves: [String: Bool]
    let activelyExploitedCVEs: [String]
    let uniqueCVEsCount, daysSincePreviousRelease: Int

    enum CodingKeys: String, CodingKey {
        case updateName = "UpdateName"
        case productVersion = "ProductVersion"
        case releaseDate = "ReleaseDate"
        case securityInfo = "SecurityInfo"
        case supportedDevices = "SupportedDevices"
        case cves = "CVEs"
        case activelyExploitedCVEs = "ActivelyExploitedCVEs"
        case uniqueCVEsCount = "UniqueCVEsCount"
        case daysSincePreviousRelease = "DaysSincePreviousRelease"
    }
}

struct SupportedModel: Codable {
    let model: String
    let url: String
    let identifiers: [String: String]

    enum CodingKeys: String, CodingKey {
        case model = "Model"
        case url = "URL"
        case identifiers = "Identifiers"
    }
}

struct XProtectPayloads: Codable {
    let xProtectFramework, pluginService: String
    let releaseDate: Date

    enum CodingKeys: String, CodingKey {
        case xProtectFramework = "com.apple.XProtectFramework.XProtect"
        case pluginService = "com.apple.XprotectFramework.PluginService"
        case releaseDate = "ReleaseDate"
    }
}

struct XProtectPlistConfigData: Codable {
    let xProtect: String
    let releaseDate: Date

    enum CodingKeys: String, CodingKey {
        case xProtect = "com.apple.XProtect"
        case releaseDate = "ReleaseDate"
    }
}

struct ModelInfo: Codable {
    let marketingName: String
    let supportedOS: [String]
    let osVersions: [Int]

    enum CodingKeys: String, CodingKey {
        case marketingName = "MarketingName"
        case supportedOS = "SupportedOS"
        case osVersions = "OSVersions"
    }
}

struct InstallationApps: Codable {
    let latestUMA: UMA
    let allPreviousUMA: [UMA]
    let latestMacIPSW: MacIPSW

    enum CodingKeys: String, CodingKey {
        case latestUMA = "LatestUMA"
        case allPreviousUMA = "AllPreviousUMA"
        case latestMacIPSW = "LatestMacIPSW"
    }
}

struct UMA: Codable {
    let title, version, build, appleSlug, url: String

    enum CodingKeys: String, CodingKey {
        case title, version, build
        case appleSlug = "apple_slug"
        case url
    }
}

struct MacIPSW: Codable {
    let macosIpswURL: String
    let macosIpswBuild, macosIpswVersion, macosIpswAppleSlug: String

    enum CodingKeys: String, CodingKey {
        case macosIpswURL = "macos_ipsw_url"
        case macosIpswBuild = "macos_ipsw_build"
        case macosIpswVersion = "macos_ipsw_version"
        case macosIpswAppleSlug = "macos_ipsw_apple_slug"
    }
}

extension MacOSDataFeed {
    init(data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601  // Use ISO 8601 date format
        self = try decoder.decode(MacOSDataFeed.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        updateHash: String,
        osVersions: [SofaOSVersion],
        xProtectPayloads: XProtectPayloads,
        xProtectPlistConfigData: XProtectPlistConfigData,
        models: [String: ModelInfo],
        installationApps: InstallationApps
    ) -> MacOSDataFeed {
        return MacOSDataFeed(
            updateHash: updateHash,
            osVersions: osVersions,
            xProtectPayloads: xProtectPayloads,
            xProtectPlistConfigData: xProtectPlistConfigData,
            models: models,
            installationApps: installationApps
        )
    }
}

class SOFA: NSObject, URLSessionDelegate {
    func URLSync(url: URL, maxRetries: Int = 3) -> (data: Data?, response: URLResponse?, error: Error?) {
        let semaphore = DispatchSemaphore(value: 0)
        let request = URLRequest(url: url)
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        var attempts = 0

        var responseData: Data?
        var response: URLResponse?
        var responseError: Error?

        // Retry loop
        while attempts < maxRetries {
            attempts += 1
            let task = session.dataTask(with: request) { data, resp, error in
                responseData = data
                response = resp
                responseError = error
                semaphore.signal()
            }
            task.resume()

            semaphore.wait()

            // Break the loop if the task succeeded or return an error other than a timeout
            if responseError == nil || (responseError! as NSError).code != NSURLErrorTimedOut {
                break
            } else if attempts < maxRetries {
                // Reset the error to try again
                responseError = nil
            }
        }

        return (responseData, response, responseError)
    }
}
