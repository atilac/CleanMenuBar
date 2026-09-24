#!/bin/sh
# Builds the .pkg the Mac App Store requires.
#
# This is a different artefact from the .dmg on GitHub, signed with different
# certificates. Getting the two confused wastes a review cycle, so:
#
#   GitHub / Homebrew   .dmg   Developer ID Application   + notarisation
#   Mac App Store       .pkg   Apple Distribution         + 3rd Party Mac
#                                                           Developer Installer
#
# App Store builds are not notarised — review takes that role — and must carry a
# provisioning profile, which Developer ID builds do not.
#
# Requires: an Apple Distribution certificate and a Mac Installer Distribution
# certificate in the keychain, plus a provisioning profile for the bundle ID.
set -e

cd "$(dirname "$0")/.."
TEAM_ID=NP9YTUN8LD
APP="CleanMenuBar"

command -v xcodebuild >/dev/null || { echo "xcodebuild not found"; exit 1; }

security find-identity -v -p codesigning | grep -q "Apple Distribution" || {
  echo "error: no Apple Distribution certificate in the keychain."
  echo "       Create one at developer.apple.com with the CSR at"
  echo "       ~/Developer/CleanMenuBar-signing/appleDistribution.csr"
  exit 1
}

# Checked without -p codesigning: an installer certificate signs packages, not
# code, so the codesigning policy filters it out and the grep would always fail.
# Apple renamed this one; both spellings are the same certificate.
security find-identity -v | grep -qE "3rd Party Mac Developer Installer|Mac Installer Distribution" || {
  echo "error: no Mac Installer Distribution certificate in the keychain."
  echo "       Create one at developer.apple.com with the CSR at"
  echo "       ~/Developer/CleanMenuBar-signing/macInstaller.csr"
  echo "       It signs the .pkg. Without it the upload fails after the build,"
  echo "       which wastes the whole archive."
  exit 1
}

rm -rf build/appstore dist-appstore
mkdir -p dist-appstore

# App Store Connect refuses a build number it has already accepted, so a
# resubmission has to increment while the marketing version stands still.
# Override with CMB_BUILD=5 Tools/build-appstore-pkg.sh; the default is whatever
# the project carries.
BUILD_ARG=""
if [ -n "$CMB_BUILD" ]; then
  BUILD_ARG="CURRENT_PROJECT_VERSION=$CMB_BUILD"
  echo "build number: $CMB_BUILD"
fi

xcodebuild -project "$APP.xcodeproj" -scheme "$APP" \
           -configuration Release \
           -archivePath build/appstore/"$APP".xcarchive \
           DEVELOPMENT_TEAM="$TEAM_ID" \
           $BUILD_ARG \
           archive

# -allowProvisioningUpdates lets Xcode create the Mac App Store profile on
# demand. It has to authenticate with the Xcode-signed-in Apple ID rather than
# the App Store Connect API key: the key is read-only, and passing it here fails
# with "You haven't been given access to cloud-managed distribution
# certificates" — a permissions message that reads like a team problem but is
# only about the key's role.
xcodebuild -exportArchive \
           -archivePath build/appstore/"$APP".xcarchive \
           -exportOptionsPlist ExportOptions-AppStore.plist \
           -exportPath dist-appstore \
           -allowProvisioningUpdates

PKG=$(find dist-appstore -name "*.pkg" | head -1)
test -n "$PKG" || { echo "error: no .pkg produced"; exit 1; }

# get-task-allow must not survive into a store build either.
if codesign -d --entitlements :- "$PKG" 2>/dev/null | grep -q get-task-allow; then
  echo "error: get-task-allow present; App Store Connect will reject this"
  exit 1
fi

echo "built: $PKG"
echo
echo "Upload with:"
echo "  xcrun altool --upload-app -f \"$PKG\" -t macos \\"
echo "    --apiKey ABX25DD23T --apiIssuer 0f395b89-aeaf-403e-ad15-c3d5558be79b"
echo
echo "The app record must already exist in App Store Connect, or the upload"
echo "fails with an unhelpful error about the bundle ID."
