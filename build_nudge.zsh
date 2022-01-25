#!/bin/zsh
#
# Build script for Nudge

# Variables
XCODE_PATH="/Applications/Xcode_13.2.1.app"
CODE_SIGN_IDENTITY="Developer ID Application: Clever DevOps Co. (9GQZ7KUFR6)"
SIGNING_IDENTITY="Developer ID Installer: Clever DevOps Co. (9GQZ7KUFR6)"
MP_SHA="71c57fcfdf43692adcd41fa7305be08f66bae3e5"
MP_BINDIR="/tmp/munki-pkg"
CONSOLEUSER=$(/usr/bin/stat -f "%Su" /dev/console)
TOOLSDIR=$(dirname $0)
BUILDSDIR="$TOOLSDIR/build"
OUTPUTSDIR="$TOOLSDIR/outputs"
MP_ZIP="/tmp/munki-pkg.zip"
XCODE_BUILD_PATH="$XCODE_PATH/Contents/Developer/usr/bin/xcodebuild"
XCODE_NOTARY_PATH="$XCODE_PATH/Contents/Developer/usr/bin/notarytool"
XCODE_STAPLER_PATH="$XCODE_PATH/Contents/Developer/usr/bin/stapler"
CURRENT_NUDGE_MAIN_BUILD_VERSION=$(/usr/libexec/PlistBuddy -c Print:CFBundleVersion $TOOLSDIR/Nudge/Info.plist)
NEWSUBBUILD=$((80620 + $(git rev-parse HEAD~0 | xargs -I{} git rev-list --count {})))

# automate the build version bump
AUTOMATED_NUDGE_BUILD="$CURRENT_NUDGE_MAIN_BUILD_VERSION.$NEWSUBBUILD"
/usr/bin/xcrun agvtool new-version -all $AUTOMATED_NUDGE_BUILD
/usr/bin/xcrun agvtool new-marketing-version $AUTOMATED_NUDGE_BUILD

# Create files to use for build process info
echo "$AUTOMATED_NUDGE_BUILD" > $TOOLSDIR/build_info.txt

# Ensure Xcode is set to run-time
sudo xcode-select -s "$XCODE_PATH"

# build nudge
echo "Building Nudge"
if [ -e $XCODE_BUILD_PATH ]; then
  XCODE_BUILD="$XCODE_BUILD_PATH"
else
  ls -la /Applications
  echo "Could not find required Xcode build. Exiting..."
  exit 1
fi
$XCODE_BUILD -project "$TOOLSDIR/Nudge.xcodeproj" CODE_SIGN_IDENTITY=$CODE_SIGN_IDENTITY OTHER_CODE_SIGN_FLAGS="--timestamp"
XCB_RESULT="$?"
if [ "${XCB_RESULT}" != "0" ]; then
    echo "Error running xcodebuild: ${XCB_RESULT}" 1>&2
    exit 1
fi

# Setup notary item
$XCODE_NOTARY_PATH store-credentials --apple-id "macadmins@cleverdevops.com" --team-id "9GQZ7KUFR6" --password "$2" nudge

# Zip application for notary
/usr/bin/ditto -c -k --keepParent "${BUILDSDIR}/Release/Nudge.app" "${BUILDSDIR}/Release/Nudge.zip"
# Notarize nudge application
$XCODE_NOTARY_PATH submit "${BUILDSDIR}/Release/Nudge.zip" --keychain-profile "nudge" --wait

# Create outputs folder
if [ -e $OUTPUTSDIR ]; then
  /bin/rm -rf $OUTPUTSDIR
fi
/bin/mkdir -p "$OUTPUTSDIR"

if ! [ -n "$1" ]; then
  echo "Did not pass option to create package"
  # Move notarized zip to outputs folder
  /bin/mv "${BUILDSDIR}/Release/Nudge.zip" "$OUTPUTSDIR"
  exit 0
fi

# move the app to the payload folder
echo "Moving Nudge.app to payload folder"
NUDGE_PKG_PATH="$TOOLSDIR/NudgePkg"
if [ -e $NUDGE_PKG_PATH ]; then
  /bin/rm -rf $NUDGE_PKG_PATH
fi
/bin/mkdir -p "$NUDGE_PKG_PATH/payload/Applications/Utilities"
/bin/mkdir -p "$NUDGE_PKG_PATH/scripts"
/usr/bin/sudo /usr/sbin/chown -R ${CONSOLEUSER}:wheel "$NUDGE_PKG_PATH"
/bin/mv "${BUILDSDIR}/Release/Nudge.app" "$NUDGE_PKG_PATH/payload/Applications/Utilities/Nudge.app"
/bin/cp "${TOOLSDIR}/build_assets/preinstall-app" "$NUDGE_PKG_PATH/scripts/preinstall"

# Download specific version of munki-pkg
echo "Downloading munki-pkg tool from github..."
if [ -f "${MP_ZIP}" ]; then
    /usr/bin/sudo /bin/rm -rf ${MP_ZIP}
fi
/usr/bin/curl https://github.com/munki/munki-pkg/archive/${MP_SHA}.zip -L -o ${MP_ZIP}
if [ -d ${MP_BINDIR} ]; then
    /usr/bin/sudo /bin/rm -rf ${MP_BINDIR}
fi
/usr/bin/unzip ${MP_ZIP} -d ${MP_BINDIR}
DL_RESULT="$?"
if [ "${DL_RESULT}" != "0" ]; then
    echo "Error downloading munki-pkg tool: ${DL_RESULT}" 1>&2
    exit 1
fi

# Create the json file for signed munkipkg Nudge pkg
/bin/cat << SIGNED_JSONFILE > "$NUDGE_PKG_PATH/build-info.json"
{
  "ownership": "recommended",
  "suppress_bundle_relocation": true,
  "identifier": "com.github.macadmins.Nudge",
  "postinstall_action": "none",
  "distribution_style": true,
  "version": "$AUTOMATED_NUDGE_BUILD",
  "name": "Nudge-$AUTOMATED_NUDGE_BUILD.pkg",
  "install_location": "/",
  "signing_info": {
    "identity": "$SIGNING_IDENTITY",
    "timestamp": true
  }
}
SIGNED_JSONFILE

# Create the signed pkg
"${MP_BINDIR}/munki-pkg-${MP_SHA}/munkipkg" "$NUDGE_PKG_PATH"
PKG_RESULT="$?"
if [ "${PKG_RESULT}" != "0" ]; then
  echo "Could not sign package: ${PKG_RESULT}" 1>&2
else
  # Notarize nudge package
  $XCODE_NOTARY_PATH submit "$NUDGE_PKG_PATH/build/Nudge-$AUTOMATED_NUDGE_BUILD.pkg" --keychain-profile "nudge" --wait
  $XCODE_STAPLER_PATH staple "$NUDGE_PKG_PATH/build/Nudge-$AUTOMATED_NUDGE_BUILD.pkg"
  # Move the signed pkg
  /bin/mv "$NUDGE_PKG_PATH/build/Nudge-$AUTOMATED_NUDGE_BUILD.pkg" "$OUTPUTSDIR"
fi

# move the la to the payload folder
echo "Moving LaunchAgent to payload folder"
NUDGE_LA_PKG_PATH="$TOOLSDIR/NudgePkgLA"
if [ -e $NUDGE_LA_PKG_PATH ]; then
  /bin/rm -rf $NUDGE_LA_PKG_PATH
fi
/bin/mkdir -p "$NUDGE_LA_PKG_PATH/payload/Library/LaunchAgents"
/bin/mkdir -p "$NUDGE_LA_PKG_PATH/scripts"
/usr/bin/sudo /usr/sbin/chown -R ${CONSOLEUSER}:wheel "$NUDGE_LA_PKG_PATH"
/bin/cp "${TOOLSDIR}/build_assets/com.github.macadmins.Nudge.plist" "$NUDGE_LA_PKG_PATH/payload/Library/LaunchAgents"
/bin/cp "${TOOLSDIR}/build_assets/postinstall-launchagent" "$NUDGE_LA_PKG_PATH/scripts/postinstall"

# Create the json file for the signed munkipkg LaunchAgent pkg
/bin/cat << SIGNED_JSONFILE > "$NUDGE_LA_PKG_PATH/build-info.json"
{
    "distribution_style": true,
    "identifier": "com.github.macadmins.Nudge.LaunchAgent",
    "install_location": "/",
    "name": "Nudge_LaunchAgent-1.0.0.pkg",
    "ownership": "recommended",
    "postinstall_action": "none",
    "suppress_bundle_relocation": true,
    "version": "1.0.0",
    "signing_info": {
        "identity": "$SIGNING_IDENTITY",
        "timestamp": true
    }
}
SIGNED_JSONFILE

# Create the signed pkg
"${MP_BINDIR}/munki-pkg-${MP_SHA}/munkipkg" "$NUDGE_LA_PKG_PATH"
PKG_RESULT="$?"
if [ "${PKG_RESULT}" != "0" ]; then
  echo "Could not sign package: ${PKG_RESULT}" 1>&2
else
  # Move the signed pkg
  /bin/mv "$NUDGE_LA_PKG_PATH/build/Nudge_LaunchAgent-1.0.0.pkg" "$OUTPUTSDIR"
fi

# move the ld to the payload folder
echo "Moving LaunchDaemon to logging payload folder"
NUDGE_LD_PKG_PATH="$TOOLSDIR/NudgePkgLogger"
if [ -e $NUDGE_LD_PKG_PATH ]; then
  /bin/rm -rf $NUDGE_LD_PKG_PATH
fi
/bin/mkdir -p "$NUDGE_LD_PKG_PATH/payload/Library/LaunchDaemons"
/bin/mkdir -p "$NUDGE_LD_PKG_PATH/scripts"
/usr/bin/sudo /usr/sbin/chown -R ${CONSOLEUSER}:wheel "$NUDGE_LD_PKG_PATH"
/bin/cp "${TOOLSDIR}/build_assets/com.github.macadmins.Nudge.logger.plist" "$NUDGE_LD_PKG_PATH/payload/Library/LaunchDaemons"
/bin/cp "${TOOLSDIR}/build_assets/postinstall-logger" "$NUDGE_LD_PKG_PATH/scripts/postinstall"

# Create the json file for the signed munkipkg LaunchAgent pkg
/bin/cat << SIGNED_JSONFILE > "$NUDGE_LD_PKG_PATH/build-info.json"
{
    "distribution_style": true,
    "identifier": "com.github.macadmins.Nudge.Logger",
    "install_location": "/",
    "name": "Nudge_Logger-1.0.1.pkg",
    "ownership": "recommended",
    "postinstall_action": "none",
    "suppress_bundle_relocation": true,
    "version": "1.0.1",
    "signing_info": {
        "identity": "$SIGNING_IDENTITY",
        "timestamp": true
    }
}
SIGNED_JSONFILE

# Create the signed pkg
"${MP_BINDIR}/munki-pkg-${MP_SHA}/munkipkg" "$NUDGE_LD_PKG_PATH"
PKG_RESULT="$?"
if [ "${PKG_RESULT}" != "0" ]; then
  echo "Could not sign package: ${PKG_RESULT}" 1>&2
else
  # Move the signed pkg
  /bin/mv "$NUDGE_LD_PKG_PATH/build/Nudge_Logger-1.0.1.pkg" "$OUTPUTSDIR"
fi
