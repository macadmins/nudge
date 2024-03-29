//
//  gdmf.swift
//  Nudge
//
//  Created by Erik Gomez on 3/27/24.
//

import Foundation

// Define the root structure
struct GDMFAssetInfo: Codable {
    let publicAssetSets: AssetSets
    let assetSets: AssetSets
    let publicRapidSecurityResponses: AssetSets?

    enum CodingKeys: String, CodingKey {
        case publicAssetSets = "PublicAssetSets"
        case assetSets = "AssetSets"
        case publicRapidSecurityResponses = "PublicRapidSecurityResponses"
    }
}

// Represents both PublicAssetSets and AssetSets
struct AssetSets: Codable {
    let iOS: [Asset]?
    let xrOS: [Asset]?
    let macOS: [Asset]?
    let visionOS: [Asset]?

    enum CodingKeys: String, CodingKey {
        case iOS = "iOS"
        case xrOS = "xrOS"
        case macOS = "macOS"
        case visionOS = "visionOS"
    }
}

// Represents an individual asset
struct Asset: Codable {
    let productVersion: String
    let build: String
    let postingDate: String
    let expirationDate: String
    let supportedDevices: [String]

    enum CodingKeys: String, CodingKey {
        case productVersion = "ProductVersion"
        case build = "Build"
        case postingDate = "PostingDate"
        case expirationDate = "ExpirationDate"
        case supportedDevices = "SupportedDevices"
    }
}

extension GDMFAssetInfo {
    init(data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601  // Use ISO 8601 date format
        self = try decoder.decode(GDMFAssetInfo.self, from: data)
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
        PublicAssetSets: AssetSets,
        AssetSets: AssetSets,
        PublicRapidSecurityResponses: AssetSets
    ) -> GDMFAssetInfo {
        return GDMFAssetInfo(
            publicAssetSets: PublicAssetSets,
            assetSets: AssetSets,
            publicRapidSecurityResponses: PublicRapidSecurityResponses
        )
    }
}

// https://arvindcs.medium.com/ssl-pinning-in-ios-30ee13f3202d
class GDMFPinnedSSL: NSObject {
    static let shared = GDMFPinnedSSL()

    // Create an array to store the public keys of the trusted certificates
    // To get these certs, download them as .cer, convert to .der, then base64 encode
    //// openssl x509 -in Apple\ Server\ Authentication\ CA.cer  -outform der -out Apple\ Server\ Authentication\ CA.der
    /// base64 -i Apple\ Server\ Authentication\ CA.der
    let trustedCertificates: [SecCertificate] = [
        // Apple Root CA
        SecCertificateCreateWithData(nil, Data(base64Encoded: "MIIEuzCCA6OgAwIBAgIBAjANBgkqhkiG9w0BAQUFADBiMQswCQYDVQQGEwJVUzETMBEGA1UEChMKQXBwbGUgSW5jLjEmMCQGA1UECxMdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxFjAUBgNVBAMTDUFwcGxlIFJvb3QgQ0EwHhcNMDYwNDI1MjE0MDM2WhcNMzUwMjA5MjE0MDM2WjBiMQswCQYDVQQGEwJVUzETMBEGA1UEChMKQXBwbGUgSW5jLjEmMCQGA1UECxMdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxFjAUBgNVBAMTDUFwcGxlIFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDkkakJH5HbHkdQ6wXtXnmELes2oldMVeyLGYne+Uts9QerIjAC6Bg++FAJ039BqJj50cpmnCRrEdCju+QbKsMflZ56DKRHi1vUFjczy8QPTc4UadHJGXL1XQ7Vf1+b8iUDulWPTV0N8WQ1IxVLFVkds5T39pyez1C6wVhQZ48ItCD3y6wsIG9wtj8BMIy3Q88PnT3zK0koGsj+zrW5DtleHNbLPbU6rfQPDgCSC7EhFi501TwN22IWq6NxkkdTVcGvL0Gz+PvjcM3mo0xFfh9Ma1CWQYnEdGILEINBhzOKgbEwWOxaBDKMaLOPHd5lc/9nXmW8Sdh2nzMUZaF3lMktAgMBAAGjggF6MIIBdjAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUK9BpR5R2Cf70a40uQKb3R01/CF4wHwYDVR0jBBgwFoAUK9BpR5R2Cf70a40uQKb3R01/CF4wggERBgNVHSAEggEIMIIBBDCCAQAGCSqGSIb3Y2QFATCB8jAqBggrBgEFBQcCARYeaHR0cHM6Ly93d3cuYXBwbGUuY29tL2FwcGxlY2EvMIHDBggrBgEFBQcCAjCBthqBs1JlbGlhbmNlIG9uIHRoaXMgY2VydGlmaWNhdGUgYnkgYW55IHBhcnR5IGFzc3VtZXMgYWNjZXB0YW5jZSBvZiB0aGUgdGhlbiBhcHBsaWNhYmxlIHN0YW5kYXJkIHRlcm1zIGFuZCBjb25kaXRpb25zIG9mIHVzZSwgY2VydGlmaWNhdGUgcG9saWN5IGFuZCBjZXJ0aWZpY2F0aW9uIHByYWN0aWNlIHN0YXRlbWVudHMuMA0GCSqGSIb3DQEBBQUAA4IBAQBcNplMLXi37Yyb3PN3m/J20ncwT8EfhYOFG5k9RzfyqZtAjizUsZAS2L70c5vu0mQPy3lPNNiiPvl4/2vIB+x9OYOLUyDTOMSxv5pPCmv/K/xZpwUJfBdAVhEedNO3iyM7R6PVbyTi69G3cN8PReEnyvFteO3ntRcXqNx+IjXKJdXZD9Zr1KIkIxH3oayPc4FgxhtbCS+SsvhESPBgOJ4V9T0mZyCKM2r3DYLP3uujL/lTaltkwGMzd/c6ByxW69oPIQ7aunMZT7XZNn/Bh1XZp5m5MkL72NVxnn6hUrcbvZNCJBIqxw8dtk2cXmPIS4AXUKqK1drk/NAJBzewdXUh")! as CFData)!,
        // Apple Server Authentication CA
        SecCertificateCreateWithData(nil, Data(base64Encoded: "MIID+DCCAuCgAwIBAgIII2l0BK3LgxQwDQYJKoZIhvcNAQELBQAwYjELMAkGA1UEBhMCVVMxEzARBgNVBAoTCkFwcGxlIEluYy4xJjAkBgNVBAsTHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRYwFAYDVQQDEw1BcHBsZSBSb290IENBMB4XDTE0MDMwODAxNTMwNFoXDTI5MDMwODAxNTMwNFowbTEnMCUGA1UEAwweQXBwbGUgU2VydmVyIEF1dGhlbnRpY2F0aW9uIENBMSAwHgYDVQQLDBdDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC5Jhawy4ercRWSjt+qPuGA11O6pGDMfIVy9zB8CU9XDUr/4V7JS1ATAmSxvTk10dcEUcEY+iL6rt+YGNa/Tk1DEPoliJ/TQIV25SKBtlRFc5qL45xIGoZ6w1Hi2pX4pH3bMN5sDsTF9WyY56b6VyAdGXN6Ds1jD7cniC7hmmiCuEBsYxYkZivnsuJUfeeIOaIbgT4C0znYl3dKMgzWCgqzBJvxcm9jqBUebDfoD9tTkNYpXLxqV5tGeAo+JOqaP6HYP/XbbqhsgrXdmTjsklaUpsVzJtGuCLLGUueOdkuJuFQPbuDZQtsqZYdGFLuWuFe7UeaEE/cNobaJrHzRIXSrAgMBAAGjgaYwgaMwHQYDVR0OBBYEFCzFbVLdMe+M7AiB7d/cykMARQHQMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUK9BpR5R2Cf70a40uQKb3R01/CF4wLgYDVR0fBCcwJTAjoCGgH4YdaHR0cDovL2NybC5hcHBsZS5jb20vcm9vdC5jcmwwDgYDVR0PAQH/BAQDAgEGMBAGCiqGSIb3Y2QGAgwEAgUAMA0GCSqGSIb3DQEBCwUAA4IBAQAj8QZ+UEGBol7TcKRJka/YzGeMoSV9xJqTOS/YafsbQVtE19lryzslCRry9OPHnOiwW/Df3SIlERWTuUle2gxmel7Xb/Bj1GWMxHpUfVZPZZr92sSyyLC4oct94EeoQBW4FhntW2GO36rQzdI6wH46nyJO39/0ThrNk//Q8EVVZDM+1OXaaKATinYwJ9S/+B529vnDAO+xg+pTbVw1xw0HAbr4Ybn+xZprQ2GBA+u6X3Cd6G+UJEvczpKoLqI1PONJ4BZ3otxruY0YQrk2lkMyxst2mTU22FbGmF3Db6V+lcLVegoCIGZ4kvJnpCMN6Am9zCExEKC9vrXdTN1GA5mZ")! as CFData)!
    ]

    func pinAsynch(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let request = URLRequest(url: url)
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: request, completionHandler: completion)
        task.resume()
    }

    func pinSync(url: URL, maxRetries: Int = 3) -> (data: Data?, response: URLResponse?, error: Error?) {
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

extension GDMFPinnedSSL: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Check if the certificate is trusted
        if let serverTrust = challenge.protectionSpace.serverTrust,
           SecTrustGetCertificateCount(serverTrust) > 0 {
            if SecTrustGetCertificateCount(serverTrust) > 1 {
                // Convert certificate stores to maps so they can be compared
                let trustedCertificatesData = trustedCertificates.map { SecCertificateCopyData($0) as Data }
                let serverCertificatesArray = SecTrustCopyCertificateChain(serverTrust)! as! [SecCertificate]
                let serverCertificatesData = serverCertificatesArray.map { SecCertificateCopyData($0) as Data }

                if !trustedCertificatesData.filter(serverCertificatesData.contains).isEmpty {
                    completionHandler(.useCredential, URLCredential(trust: serverTrust))
                    return
                }
            } else {
                // Single certs we just loop through the internal nudge trust and compare if any exist
                let serverCertificate = SecTrustCopyCertificateChain(serverTrust)!
                let serverCertificateData = SecCertificateCopyData(serverCertificate as! SecCertificate) as Data

                for trustedCertificate in trustedCertificates {
                    let trustedCertificateData = SecCertificateCopyData(trustedCertificate) as Data
                    if serverCertificateData == trustedCertificateData {
                        completionHandler(.useCredential, URLCredential(trust: serverTrust))
                        return
                    }
                }
            }
        }
        // If the certificate is not trusted, cancel the request
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}
