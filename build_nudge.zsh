#!/bin/zsh
#
# Build script for Nudge

# Variables
SIGNING_IDENTITY="Developer ID Installer: Clever DevOps Co. (9GQZ7KUFR6)"
MP_SHA="71c57fcfdf43692adcd41fa7305be08f66bae3e5"
MP_BINDIR="/tmp/munki-pkg"
CONSOLEUSER=$(/usr/bin/stat -f "%Su" /dev/console)
TOOLSDIR=$(dirname $0)
BUILDSDIR="$TOOLSDIR/build"
OUTPUTSDIR="$TOOLSDIR/outputs"
MP_ZIP="/tmp/munki-pkg.zip"
XCODE_BUILD_PATH="/Applications/Xcode_12.4.app/Contents/Developer/usr/bin/xcodebuild"
CURRENT_NUDGE_MAIN_BUILD_VERSION=$(/usr/libexec/PlistBuddy -c Print:CFBundleVersion $TOOLSDIR/Nudge/Info.plist)
DATE=$(/bin/date -u "+%m%d%Y%H%M%S")

# automate the build version bump
AUTOMATED_NUDGE_BUILD="$CURRENT_NUDGE_MAIN_BUILD_VERSION.$DATE"
/usr/bin/xcrun agvtool new-version -all $AUTOMATED_NUDGE_BUILD
/usr/bin/xcrun agvtool new-marketing-version $AUTOMATED_NUDGE_BUILD

# Create files to use for build process info
echo "$AUTOMATED_NUDGE_BUILD" > $TOOLSDIR/build_info.txt

# build nudge
echo "Building Nudge"
if [ -e $XCODE_BUILD_PATH ]; then
  XCODE_BUILD="$XCODE_BUILD_PATH"
else
  XCODE_BUILD="xcodebuild"
fi
$XCODE_BUILD -project "$TOOLSDIR/Nudge.xcodeproj" CODE_SIGN_IDENTITY="Apple Distribution: Clever DevOps Co. (9GQZ7KUFR6)"
XCB_RESULT="$?"
if [ "${XCB_RESULT}" != "0" ]; then
    echo "Error running xcodebuild: ${XCB_RESULT}" 1>&2
    exit 1
fi

if ! [ -n "$1" ]; then
  echo "Did not pass option to create package"
  exit 0
fi

# move the app to the payload folder
echo "Moving Nudge.app to payload folder"
/bin/mkdir -p "$TOOLSDIR/NudgePkg/payload/Applications/Utilities"
/bin/mkdir -p "$TOOLSDIR/NudgePkg/scripts"
/usr/bin/sudo /usr/sbin/chown -R ${CONSOLEUSER}:wheel "$TOOLSDIR/NudgePkg"
/bin/mv "${BUILDSDIR}/Release/Nudge.app" "$TOOLSDIR/NudgePkg/payload/Applications/Utilities/Nudge.app"
/bin/cp "${TOOLSDIR}/build_assets/preinstall" "$TOOLSDIR/NudgePkg/scripts"

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
/bin/cat << SIGNED_JSONFILE > "$TOOLSDIR/NudgePkg/build-info.json"
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
"${MP_BINDIR}/munki-pkg-${MP_SHA}/munkipkg" "$TOOLSDIR/NudgePkg"
PKG_RESULT="$?"
if [ "${PKG_RESULT}" != "0" ]; then
  echo "Could not sign package: ${PKG_RESULT}" 1>&2
else
  # Create outputs folder
  /bin/mkdir -p "$OUTPUTSDIR"
  # Move the signed pkg
  /bin/mv "$TOOLSDIR/NudgePkg/build/Nudge-$AUTOMATED_NUDGE_BUILD.pkg" "$OUTPUTSDIR"
fi

# move the la to the payload folder
echo "Moving LaunchAgent to payload folder"
/bin/mkdir -p "$TOOLSDIR/NudgePkgLA/payload/Library/LaunchAgents"
/bin/mkdir -p "$TOOLSDIR/NudgePkgLA/scripts"
/usr/bin/sudo /usr/sbin/chown -R ${CONSOLEUSER}:wheel "$TOOLSDIR/NudgePkgLA"
/bin/cp "${TOOLSDIR}/build_assets/com.github.macadmins.Nudge.plist" "$TOOLSDIR/NudgePkgLA/payload/Library/LaunchAgents"
/bin/cp "${TOOLSDIR}/build_assets/postinstall" "$TOOLSDIR/NudgePkgLA/scripts"

# Create the json file for the signed munkipkg LaunchAgent pkg
/bin/cat << SIGNED_JSONFILE > "$TOOLSDIR/NudgePkgLA/build-info.json"
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
"${MP_BINDIR}/munki-pkg-${MP_SHA}/munkipkg" "$TOOLSDIR/NudgePkgLA"
PKG_RESULT="$?"
if [ "${PKG_RESULT}" != "0" ]; then
  echo "Could not sign package: ${PKG_RESULT}" 1>&2
else
  # Create outputs folder
  /bin/mkdir -p "$OUTPUTSDIR"
  # Move the signed pkg
  /bin/mv "$TOOLSDIR/NudgePkgLA/build/Nudge_LaunchAgent-1.0.0.pkg" "$OUTPUTSDIR"
fi
