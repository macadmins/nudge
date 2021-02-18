//
//  DefaultPreferencesUMAD.swift
//  Nudge
//
//  Created by Erik Gomez on 2/18/21.
//

import Foundation

// UMAD
// optionalFeatures - UMAD
// TODO: Profile support - not needed for now
let alwaysShowManualEnerllment = nudgeJSONPreferences?.optionalFeatures?.umadFeatures?.alwaysShowManulEnrollment ?? false
let depScreenShotPath = nudgeJSONPreferences?.optionalFeatures?.umadFeatures?.depScreenShotPath ?? ""
let disableManualEnrollmentForDEP = nudgeJSONPreferences?.optionalFeatures?.umadFeatures?.disableManualEnrollmentForDEP ?? false
let enforceMDMInstallation = nudgeJSONPreferences?.optionalFeatures?.umadFeatures?.enforceMDMInstallation ?? false
let manulEnrollmentPath = nudgeJSONPreferences?.optionalFeatures?.umadFeatures?.manualEnrollmentPath ?? "https://apple.com"
let mdmInformationButtonPath = nudgeJSONPreferences?.optionalFeatures?.umadFeatures?.mdmInformationButtonPath ??  "https://github.com/macadmins/umad"
let mdmProfileIdentifier = nudgeJSONPreferences?.optionalFeatures?.umadFeatures?.mdmProfileIdentifier ?? "com.example.mdm.profile"
let mdmRequiredInstallationDate = nudgeJSONPreferences?.optionalFeatures?.umadFeatures?.mdmRequiredInstallationDate ?? Date(timeIntervalSince1970: 0)
let uamdmScreenShotPath = nudgeJSONPreferences?.optionalFeatures?.umadFeatures?.uamdmScreenShotPath ?? ""

// userInterface - UMAD
// TODO: Profile support - not needed for now
func getMDMUserInterfaceJSON() -> UmadElement? {
    if Utils().demoModeEnabled() {
        return nil
    }
    let updateElements = nudgeJSONPreferences?.userInterface?.umadElements
    if updateElements != nil {
        for (_ , subPreferences) in updateElements!.enumerated() {
            if subPreferences.language == language {
                return subPreferences
            }
        }
    }
    return nil
}
let mdmActionButtonManualText = getMDMUserInterfaceJSON()?.actionButtonManualText ?? "Manually Enroll"
let mdmActionButtonText = getMDMUserInterfaceJSON()?.actionButtonText ?? ""
let mdmActionButtonUAMDMText = getMDMUserInterfaceJSON()?.actionButtonUAMDMText ?? "Open System Preferences"
let mdmInformationButtonText = getMDMUserInterfaceJSON()?.informationButtonText ?? "More Info"
let mdmMainContentHeader = getMDMUserInterfaceJSON()?.mainContentHeader ?? "This process does not require a restart"
let mdmMainContentNote = getMDMUserInterfaceJSON()?.mainContentNote ?? "Important Notes"
let mdmMainContentText = getMDMUserInterfaceJSON()?.mainContentText ?? "Enrollment into MDM is required to ensure that IT can protect your computer with basic security necessities like encryption and threat detection.\n\nIf you do not enroll into MDM you may lose access to some items necessary for your day-to-day tasks.\n\nTo enroll, just look for the below notification, and click Details. Once prompted, log in with your username and password."
let mdmMainContentUAMDMText = getMDMUserInterfaceJSON()?.mainContentUAMDMText ?? "Thank you for enrolling your device into MDM. We sincerely appreciate you doing this in a timely manner.\n\nUnfortunately, your device has been detected as only partially enrolled into our system.\n\nPlease go to System Preferences -> Profiles, click on the Device Enrollment profile and click on the approve button."
let mdmMainHeader = getMDMUserInterfaceJSON()?.mainHeader ?? "Your device requires management"
let mdmPrimaryQuitButtonText = getMDMUserInterfaceJSON()?.primaryQuitButtonText ?? "Later"
let mdmSecondaryQuitButtonText = getMDMUserInterfaceJSON()?.secondaryQuitButtonText ?? "I understand"
let mdmSubHeader = getMDMUserInterfaceJSON()?.subHeader ?? "A friendly reminder from your local IT team"

