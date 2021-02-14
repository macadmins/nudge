# Nudge (macadmin's Slack #nudge)
<img src="/assets/NudgeIcon.png" width=25% height=25%>
Nudge is application for enforcing macOS updates, written in Swift/SwiftUI 5.2. In order to use the newest features of Swift, Nudge will only work on macOS 11.0 and higher.

This is a replacement for the original Nudge, which was written in Python 2/3. If you need to enforce macOS updates for earlier versions, it is recommend to use [nudge-python](https://github.com/macadmins/nudge-python).

Some enhancements to the SwiftUI version over nudge-python
- An enhanced UI, redesigned with new functionality
- A new UI called `simpleMode`
- Support for localization
- Support for Apple Silicon macs
- Every button's text can be customized
- Every text element except for the left portion can be customized

## OS support
The following operating system and versions have been tested.
- 11.0, 11.0.1, 11.1, 11.2, 11.2.1

## Tools that work with Nudge
Any MDM that supports the installation of packages (.pkgs) and profiles (.mobileconfig) can deploy and enforce Nudge.

## Nudge functionality overview
- Nudge consists of the following three components
 - Nudge.app installed to `/Applications/Utilities/Nudge.app`
 - a LaunchAgent installed to `/Library/LaunchAgents`
 - a Preference file, either in JSON or mobileconfig format (coming soon)

- Rather than trying to install updates via `softwareupdate`, Nudge merely prompts users to install updates via Apple approved/tested methods - System Preferences and major application upgrades (Ex: `Install macOS Big Sur.app`).

- With the optionally provided LaunchAgent package, Nudge will open every 30 minutes, at the 0 and 30 minute mark. If you find this behavior too aggressive, you will need to create your own LaunchAgent.

# Deploy Nudge
After installing Nudge through the package, you can attempt to open Nudge through `Finder` - but you will quickly realize that it immediately closed.

This is because Nudge has not been configured! Please read on to learn how to engage with Nudge through the command line.

## Command Line
To open Nudge through the command-line application, open `Terminal` and run the following command:

```
/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge
```

If you have just installed Nudge for the first time, you will likely see the following message returned:

```
/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge
Device fully up-to-date.
```
### Demo Mode
In order to trigger Nudge in demo mode, simply pass the `-demo-mode` argument

```
/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge \
-demo-mode
```

This will open Nudge in the English localization and allow you to test the buttons, as well as Light/Dark mode.

If you'd like to trigger `simpleMode` in Demo mode, chain the both `-demo-mode` and `-simple-mode` arguments

```
/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge \
-demo-mode \
-simple-mode
```

### Simple Mode
If you'd like to force simple mode (and don't want to use the built in preferences configuration), simply pass the `-simple-mode` argument

```
/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge \
-simple-mode
```

## JSON Support
Nudge has support for both a local JSON and a remote JSON.

By default, Nudge will look for a JSON located at `/Library/Preferences/com.github.macadmins.Nudge.json`

### Using the -json-url argument
In order to download a JSON from a website, simple pass the `-json-url` argument.

```
/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge \
-json-url \
"https://raw.githubusercontent.com/macadmins/nudge/Example%20Assets/com.github.macadmins.Nudge.json"
```

While the `-json-url` argument is mainly designed for web urls, you can actually pass it a file path as well if you don't want to deploy a json to `/Library/Preferences` or simply want to test another json file.

```
/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge \
-json-url \
"file:///path/to/your.json"`
```

## Scheduling Nudge to run
TODO: Mention LaunchAgent pkg

## Configuration
Nudge offers significant customization and can be overwhelming, but fear not, you don't have to customize everything :smile:

### Small Example
In this example, Nudge will do the following:

- Open up in `simpleMode`
- Enforce Big Sur version `11.2.1` to the following operating systems
  - 11.0, 11.0.1, 11.1, 11.2
  - an enforcement date of February 28th, 2021
- The `More Info` button will open up to the [Apple Big Sur release notes](https://support.apple.com/en-us/HT211896)
```
{
    "optionalFeatures": {
        "simpleMode": true
    },
    "osVersionRequirements": [
        {
            "aboutUpdateURL": "https://support.apple.com/en-us/HT211896",
            "requiredInstallationDate": "2021-02-28T00:00:00Z",
            "requiredMinimumOSVersion": "11.2.1",
            "targetedOSVersions": [
                "11.0",
                "11.0.1",
                "11.1",
                "11.2"
            ]
        }
    ],
}
```

### Full Example
TODO: This needs to be finished and fully documented.
```
{
    "optionalFeatures": {
        "allowedDeferrals": 1000000,
        "allowedDeferralsUntilForcedSecondaryQuitButton": 14,
        "attemptToFetchMajorUpgrade": true,
        "enforceMinorUpdates": true,
        "iconDarkPath": "/somewhere/logoDark.png",
        "iconLightPath": "/somewhere/logoLight.png",
        "maxRandomDelayInSeconds": 1200,
        "noTimers": false,
        "randomDelay": false,
        "screenShotDarkPath": "/somewhere/screenShotDark.jpg",
        "screenShotLightPath": "/somewhere/screenShotLight.jpg",
        "simpleMode": false
    },
    "osVersionRequirements": [
        {
            "aboutUpdateURL": "https://support.apple.com/en-us/HT211896",
            "majorUpgradeAppPath": "/Applications/Install macOS Big Sur.app",
            "requiredInstallationDate": "2021-02-28T00:00:00Z",
            "requiredMinimumOSVersion": "11.2.1",
            "targetedOSVersions": [
                "11.0",
                "11.0.1",
                "11.1",
                "11.2"
            ]
        }
    ],
    "userExperience": {
        "approachingRefreshCycle": 6000,
        "approachingWindowTime": 72,
        "elapsedRefreshCycle": 300,
        "imminentRefeshCycle": 600,
        "imminentWindowTime": 24,
        "initialRefreshCycle": 18000,
        "nudgeRefreshCycle": 60
    },
    "userInterface": {
        "updateElements": [
            {
                "_language": "en",
                "actionButtonText": "Update Device",
                "informationButtonText": "More Info",
                "mainContentHeader": "Your device will restart during this update",
                "mainContentNote": "Important Notes",
                "mainContentSubHeader": "Updates can take around 30 minutes to complete",
                "mainContentText": "A fully up-to-date device is required to ensure that IT can your accurately protect your device.\n\nIf you do not update your device, you may lose access to some items necessary for your day-to-day tasks.\n\nTo begin the update, simply click on the button below and follow the provided steps.",
                "mainHeader": "Your device requires a security update",
                "primaryQuitButtonText": "Later",
                "secondaryQuitButtonText": "I understand",
                "subHeader": "A friendly reminder from your local IT team"
            },
            {
                "_language": "fr",
                "actionButtonText": "Mettre à jour l'appareil",
                "informationButtonText": "Plus d'informations",
                "mainContentHeader": "Votre appareil redémarrera pendant cette mise à jour",
                "mainContentNote": "Notes Importantes",
                "mainContentSubHeader": "Les mises à jour peuvent prendre environ 30 minutes.",
                "mainContentText": "Un appareil entièrement à jour est nécessaire pour garantir que le service informatique peut protéger votre appareil avec précision.\n\n Si vous ne mettez pas à jour votre appareil, vous risquez de perdre l'accès à certains éléments nécessaires à vos tâches quotidiennes.\n\nPour commencer la mise à jour, cliquez simplement sur le bouton ci-dessous et suivez les étapes fournies.",
                "mainHeader": "Votre appareil nécessite une mise à jour de sécurité",
                "primaryQuitButtonText": "Plus tard",
                "secondaryQuitButtonText": "Je comprends",
                "subHeader": "Un rappel amical de votre équipe informatique locale"
            }
        ]
    }
}
```

## Localization
TODO: Need to write

# Nudge Screenshots
TODO: Need to update

<img src="/assets/demo_light_1.png" width=50% height=50%>
<img src="/assets/demo_light_2.png" width=50% height=50%>
<img src="/assets/demo_light_2.png" width=50% height=50%>
<img src="/assets/demo_dark_1.png" width=50% height=50%>
