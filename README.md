# Nudge (macadmin's Slack #nudge)
<img src="/assets/NudgeIcon.png" width=25% height=25%>

Nudge is application for enforcing macOS updates, written in Swift/SwiftUI 5.2. In order to use the newest features of Swift, Nudge will only work on macOS 11.0 and higher.

This is a replacement for the original Nudge, which was written in Python 2/3. If you need to enforce macOS updates for earlier versions, it is recommend to use [nudge-python](https://github.com/macadmins/nudge-python).

Some enhancements to the SwiftUI version over nudge-python
- An enhanced UI, redesigned with new functionality
- A new UI called `simpleMode`
- Support for localization
- Support for Apple Silicon macs
- Every one of the buttons can be customized
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

## Command Line Arguments
[For a full listing of the available command line arguments, please see the wiki](https://github.com/macadmins/nudge/wiki/Command-Line-Arguments)

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

If you'd like to force the icon in Demo mode, chain the both `-demo-mode` and `-force-screenshot-icon` arguments

```
/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge \
-demo-mode \
-force-screenshot-icon
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

While the `-json-url` argument is mainly designed for web urls, you can actually pass it a `file://` path as well if you don't want to deploy a json to `/Library/Preferences` or simply want to test your workflow.

```
/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge \
-json-url \
"file:///Users/YOURUSERNAME/Downloads/nudge/Example%20Assets/com.github.macadmins.Nudge.json"`
```

** Note: ** Spaces must be converted to `%20`, just as a standard url. This is required both for web and local assets

## Scheduling Nudge to run
Every release of Nudge comes with an optional LaunchAgent package.

This LaunchAgent will open Nudge every 30 minutes, at the 0 and 30 minute mark. If you find this behavior too aggressive, you will need to create your own LaunchAgent.

Example LaunchAgent
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.github.macadmins.Nudge</string>
	<key>LimitLoadToSessionType</key>
	<array>
		<string>Aqua</string>
	</array>
	<key>ProgramArguments</key>
	<array>
		<string>/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge</string>
		<!-- <string>-json-url</string> -->
		<!-- <string>https://raw.githubusercontent.com/macadmins/nudge/main/Nudge/example.json</string> -->
		<!-- <string>-demo-mode</string> -->
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>StartCalendarInterval</key>
	<array>
		<dict>
			<key>Minute</key>
			<integer>0</integer>
		</dict>
		<dict>
			<key>Minute</key>
			<integer>30</integer>
		</dict>
	</array>
</dict>
</plist>
```

## Localization
By default, Nudge only supports the English (en) locale. If you need additional localizations, you will need the following:

- Localization.strings for locale of the left side of Nudge and the `Additional Machine Details` view
- Preferences file

The following example would add support for the French (fr) locale.

** Note: **There is already a French localization string to fill the rest of the UI

```
{
    "userInterface": {
        "updateElements": [
            {
                "_language": "es",
                "actionButtonText": "Actualizar dispositivo",
                "informationButtonText": "Más información",
                "mainContentHeader": "Su dispositivo se reiniciará durante esta actualización",
                "mainContentNote": "Notas importantes",
                "mainContentSubHeader": "Las actualizaciones pueden tardar unos 30 minutos en completarse",
                "mainContentText": "Se requiere un dispositivo completamente actualizado para garantizar que IT pueda proteger su dispositivo con precisión.\n\nSi no actualiza su dispositivo, es posible que pierda el acceso a algunos elementos necesarios para sus tareas diarias.\n\nPara comenzar la actualización, simplemente haga clic en el botón Actualizar dispositivo y siga los pasos proporcionados.",
                "mainHeader": "Tu dispositivo requiere una actualización de seguridad",
                "primaryQuitButtonText": "Más tarde",
                "secondaryQuitButtonText": "Entiendo",
                "subHeader": "Un recordatorio amistoso de su equipo de IT local"
            },
            {
                "_language": "fr",
                "actionButtonText": "Mettre à jour l'appareil",
                "informationButtonText": "Plus d'informations",
                "mainContentHeader": "Votre appareil redémarrera pendant cette mise à jour",
                "mainContentNote": "Notes Importantes",
                "mainContentSubHeader": "Les mises à jour peuvent prendre environ 30 minutes.",
                "mainContentText": "Un appareil entièrement à jour est nécessaire pour garantir que le service informatique peut protéger votre appareil avec précision.\n\n Si vous ne mettez pas à jour votre appareil, vous risquez de perdre l'accès à certains éléments nécessaires à vos tâches quotidiennes.\n\nPour commencer la mise à jour, cliquez simplement sur le bouton Mettre à jour le périphérique et suivez les étapes fournies.",
                "mainHeader": "Votre appareil nécessite une mise à jour de sécurité",
                "primaryQuitButtonText": "Plus tard",
                "secondaryQuitButtonText": "Je comprends",
                "subHeader": "Un rappel amical de votre équipe informatique locale"
            }
        ]
    }
}
```

## Configuration
Nudge offers significant customization, which might be overwhelming. But don't worry, you don't have to customize everything. :smile:

[For a full listing of the available preferences, please see the wiki](https://github.com/macadmins/nudge/wiki/Preferences)

### Small Example
In this example, Nudge will do the following:

- Open up in `simpleMode`
- Enforce Big Sur version `11.2.1` to the following operating systems
  - 11.0, 11.0.1, 11.1, 11.2
  - an enforcement date of February 28th, 2021
- The `More Info` button will open up to the [Apple Big Sur release notes](https://support.apple.com/en-us/HT211896)
```
{
    "userInterface": {
      "simpleMode": false
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
```
{
    "optionalFeatures": {
        "attemptToFetchMajorUpgrade": true
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
        "allowedDeferrals": 1000000,
        "allowedDeferralsUntilForcedSecondaryQuitButton": 14,
        "approachingRefreshCycle": 6000,
        "approachingWindowTime": 72,
        "elapsedRefreshCycle": 300,
        "imminentRefeshCycle": 600,
        "imminentWindowTime": 24,
        "initialRefreshCycle": 18000,
        "maxRandomDelayInSeconds": 1200,
        "noTimers": false,
        "nudgeRefreshCycle": 60,
        "randomDelay": false
    },
    "userInterface": {
        "forceScreenShotIcon": false,
        "iconDarkPath": "/somewhere/logoDark.png",
        "iconLightPath": "/somewhere/logoLight.png",
        "screenShotDarkPath": "/somewhere/screenShotDark.jpg",
        "screenShotLightPath": "/somewhere/screenShotLight.jpg",
        "simpleMode": false,
        "updateElements": [
            {
                "_language": "es",
                "actionButtonText": "Actualizar dispositivo",
                "informationButtonText": "Más información",
                "mainContentHeader": "Su dispositivo se reiniciará durante esta actualización",
                "mainContentNote": "Notas importantes",
                "mainContentSubHeader": "Las actualizaciones pueden tardar unos 30 minutos en completarse",
                "mainContentText": "Se requiere un dispositivo completamente actualizado para garantizar que IT pueda proteger su dispositivo con precisión.\n\nSi no actualiza su dispositivo, es posible que pierda el acceso a algunos elementos necesarios para sus tareas diarias.\n\nPara comenzar la actualización, simplemente haga clic en el botón Actualizar dispositivo y siga los pasos proporcionados.",
                "mainHeader": "Tu dispositivo requiere una actualización de seguridad",
                "primaryQuitButtonText": "Más tarde",
                "secondaryQuitButtonText": "Entiendo",
                "subHeader": "Un recordatorio amistoso de su equipo de IT local"
            },
            {
                "_language": "fr",
                "actionButtonText": "Mettre à jour l'appareil",
                "informationButtonText": "Plus d'informations",
                "mainContentHeader": "Votre appareil redémarrera pendant cette mise à jour",
                "mainContentNote": "Notes Importantes",
                "mainContentSubHeader": "Les mises à jour peuvent prendre environ 30 minutes.",
                "mainContentText": "Un appareil entièrement à jour est nécessaire pour garantir que le service informatique peut protéger votre appareil avec précision.\n\n Si vous ne mettez pas à jour votre appareil, vous risquez de perdre l'accès à certains éléments nécessaires à vos tâches quotidiennes.\n\nPour commencer la mise à jour, cliquez simplement sur le bouton Mettre à jour le périphérique et suivez les étapes fournies.",
                "mainHeader": "Votre appareil nécessite une mise à jour de sécurité",
                "primaryQuitButtonText": "Plus tard",
                "secondaryQuitButtonText": "Je comprends",
                "subHeader": "Un rappel amical de votre équipe informatique locale"
            }
        ]
    }
}
```

# Examples of the User Interface

## simpleMode

### English

#### Light
<img src="/assets/simple_mode/demo_simple_light_1.png" width=75% height=75%>
<img src="/assets/simple_mode/demo_simple_light_2.png" width=75% height=75%>

#### Dark
<img src="/assets/simple_mode/demo_simple_dark_1.png" width=75% height=75%>
<img src="/assets/simple_mode/demo_simple_dark_2.png" width=75% height=75%>

### Localized (Spanish)
#### Light
<img src="/assets/simple_mode/demo_simple_light_localized.png" width=75% height=75%>

#### Dark
<img src="/assets/simple_mode/demo_simple_dark_localized.png" width=75% height=75%>

## standardMode
### English
#### Light
<img src="/assets/standard_mode/demo_light_1_icon.png" width=75% height=75%>
<img src="/assets/standard_mode/demo_light_1_no_icon.png" width=75% height=75%>
<img src="/assets/standard_mode/demo_light_2_icon.png" width=75% height=75%>
<img src="/assets/standard_mode/demo_light_2_no_icon.png" width=75% height=75%>
<img src="/assets/standard_mode/demo_light_3.png" width=75% height=75%>
<img src="/assets/standard_mode/demo_light_4.png" width=75% height=75%>

#### Dark
<img src="/assets/standard_mode/demo_dark_1_icon.png" width=75% height=75%>
<img src="/assets/standard_mode/demo_dark_1_no_icon.png" width=75% height=75%>
<img src="/assets/standard_mode/demo_dark_2_icon.png" width=75% height=75%>
<img src="/assets/standard_mode/demo_dark_2_no_icon.png" width=75% height=75%>
<img src="/assets/standard_mode/demo_dark_3.png" width=75% height=75%>
<img src="/assets/standard_mode/demo_dark_4.png" width=75% height=75%>

### Localized (Spanish)
#### Light
<img src="/assets/standard_mode/demo_light_2_icon_localized.png" width=75% height=75%>
<img src="/assets/standard_mode/demo_light_4_localized.png" width=75% height=75%>

#### Dark
<img src="/assets/standard_mode/demo_dark_2_icon_localized.png" width=75% height=75%>
<img src="/assets/standard_mode/demo_dark_4_localized.png" width=75% height=75%>
