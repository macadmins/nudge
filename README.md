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

If you are able to host JSONs, you can optionally pass a URL to Nudge. If you are not able to host JSON files, you can deploy a local JSON to `/Library/Preferences/com.github.macadmins.Nudge.json`

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
/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge -demo-mode
```

This will open Nudge in the English localization and allow you to test the buttons, as well as Light/Dark mode.

If you'd like to trigger `simpleMode` in Demo mode, chain the both `-demo-mode` and `-simple-mode` arguments

```
/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge -demo-mode -simple-mode
```

### Simple Mode
If you'd like to force simple mode (and don't want to use the built in preferences configuration), simply pass the `-simple-mode` argument

```
/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge -simple-mode
```

## JSON Support

# Nudge Screenshots
<img src="/assets/demo_light_1.png" width=50% height=50%>
<img src="/assets/demo_light_2.png" width=50% height=50%>
<img src="/assets/demo_light_2.png" width=50% height=50%>
<img src="/assets/demo_dark_1.png" width=50% height=50%>
