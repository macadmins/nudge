//
//  SoftwareUpdate.swift
//  Nudge
//
//  Created by Rory Murdock on 2/10/21.
//

import Foundation
import os

class SoftwareUpdate {
    func list() -> String {
        let (output, error, exitCode) = SubProcessUtilities().runProcess(launchPath: "/usr/sbin/softwareupdate", arguments: ["--list", "--all"])

        if exitCode != 0 {
            LogManager.error("Error listing software updates: \(error)", logger: softwareupdateListLog)
            return error
        } else {
            LogManager.info("\(output)", logger: softwareupdateListLog)
            return output
        }
    }

    func download() {
        LogManager.notice("enforceMinorUpdates: \(OptionalFeatureVariables.enforceMinorUpdates)", logger: softwareupdateDownloadLog)

        if DeviceManager().getCPUTypeString() == "Apple Silicon" && !AppStateManager().requireMajorUpgrade() {
            LogManager.debug("Apple Silicon devices do not support automated softwareupdate downloads for minor updates. Please use MDM for this functionality.", logger: softwareupdateListLog)
            return
        }

        if AppStateManager().requireMajorUpgrade() {
            guard FeatureVariables.actionButtonPath == nil else { return }

            if OptionalFeatureVariables.attemptToFetchMajorUpgrade, !majorUpgradeAppPathExists, !majorUpgradeBackupAppPathExists {
                LogManager.notice("Device requires major upgrade - attempting download", logger: softwareupdateListLog)
                let (output, error, exitCode) = SubProcessUtilities().runProcess(launchPath: "/usr/sbin/softwareupdate", arguments: ["--fetch-full-installer", "--full-installer-version", OSVersionRequirementVariables.requiredMinimumOSVersion])

                if exitCode != 0 {
                    LogManager.error("Error downloading software update: \(error)", logger: softwareupdateDownloadLog)
                } else {
                    LogManager.info("\(output)", logger: softwareupdateDownloadLog)
                    GlobalVariables.fetchMajorUpgradeSuccessful = true
                    // Update the state based on the download result
                }
            } else if majorUpgradeAppPathExists || majorUpgradeBackupAppPathExists {
                LogManager.notice("Found major upgrade application or backup - skipping download", logger: softwareupdateListLog)
            }
        } else {
            if OptionalFeatureVariables.disableSoftwareUpdateWorkflow {
                LogManager.notice("Skipping running softwareupdate because it's disabled by a preference.", logger: softwareupdateListLog)
                return
            }
            let softwareupdateList = self.list()
            let updateLabel = extractUpdateLabel(from: softwareupdateList)

            if !softwareupdateList.contains(OSVersionRequirementVariables.requiredMinimumOSVersion) || updateLabel.isEmpty {
                LogManager.notice("Software update did not find \(OSVersionRequirementVariables.requiredMinimumOSVersion) available for download - skipping download attempt", logger: softwareupdateListLog)
                return
            }

            LogManager.notice("Software update found \(updateLabel) available for download - attempting download", logger: softwareupdateListLog)
            let (output, error, exitCode) = SubProcessUtilities().runProcess(launchPath: "/usr/sbin/softwareupdate", arguments: ["--download", updateLabel])

            if exitCode != 0 {
                LogManager.error("Error downloading software updates: \(error)", logger: softwareupdateDownloadLog)
            } else {
                LogManager.info("\(output)", logger: softwareupdateDownloadLog)
            }
        }
    }

    private func extractUpdateLabel(from softwareupdateList: String) -> String {
        let lines = softwareupdateList.split(separator: "\n")
        var updateLabel: String?

        for line in lines {
            if line.contains("Label:") {
                let labelPart = line.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
                if labelPart.count > 1 && labelPart[1].contains(OSVersionRequirementVariables.requiredMinimumOSVersion) {
                    updateLabel = labelPart[1]
                    break
                }
            }
        }

        return updateLabel ?? ""
    }
}
