#!/bin/zsh
#
# Build script for Nudge

# Variables
SIGNING_IDENTITY="Developer ID Installer: Clever DevOps Co. (9GQZ7KUFR6)"
MP_SHA="71c57fcfdf43692adcd41fa7305be08f66bae3e5"
MP_BINDIR="/tmp/munki-pkg"
CONSOLEUSER=$(/usr/bin/stat -f "%Su" /dev/console)
NUDGE_VERSION=0.0.2
TOOLSDIR=$(dirname $0)
BUILDSDIR="$TOOLSDIR/build"
OUTPUTSDIR="$TOOLSDIR/outputs"
MP_ZIP="/tmp/munki-pkg.zip"

if [ -n "$1" ]; then
  DATE=$4
else
  DATE=$(/bin/date -u "+%m%d%Y%H%M%S")
fi

# build nudge
echo "Building Nudge"
/Applications/Xcode_12.4.app/Contents/Developer/usr/bin/xcodebuild -project Nudge.xcodeproj CODE_SIGN_IDENTITY="Apple Distribution: Clever DevOps Co."

XCB_RESULT="$?"
if [ "${XCB_RESULT}" != "0" ]; then
    echo "Error running xcodebuild: ${XCB_RESULT}" 1>&2
    exit 1
fi

# move the app to the payload folder
echo "Moving Nudge.app to payload folder"
/bin/mkdir -p "$TOOLSDIR/NudgePkg/payload/Applications/Utilities"
/usr/bin/sudo /usr/sbin/chown -R ${CONSOLEUSER}:wheel "$TOOLSDIR/NudgePkg"
/bin/mv "${BUILDSDIR}/Release/Nudge.app" "$TOOLSDIR/NudgePkg/payload/Applications/Utilities/Nudge.app"

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

# Create the json file for signed munkipkg
/bin/cat << SIGNED_JSONFILE > "$TOOLSDIR/NudgePkg/build-info.json"
{
  "ownership": "recommended",
  "suppress_bundle_relocation": true,
  "identifier": "com.github.macadmins.Nudge",
  "postinstall_action": "none",
  "distribution_style": true,
  "version": "$NUDGE_VERSION.$DATE",
  "name": "Nudge-$NUDGE_VERSION.$DATE.pkg",
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
  /bin/mv "$TOOLSDIR/NudgePkg/build/Nudge-$NUDGE_VERSION.$DATE.pkg" "$OUTPUTSDIR"
fi
