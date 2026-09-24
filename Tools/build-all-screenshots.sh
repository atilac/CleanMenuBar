#!/bin/sh
# Captures the app in each language and composes the App Store frames.
#
# Every capture is taken from a freshly launched app with defaults reset, so no
# toggle left on from testing and no half-applied language reaches a store
# listing. A frame showing "Português (Brasil)" selected in an English window
# reads as a bug in the app, not as a screenshot mistake.
set -e

cd "$(dirname "$0")/.."
APP=build/Build/Products/Debug/CleanMenuBar.app/Contents/MacOS/CleanMenuBar
DOMAIN=~/Library/Containers/com.atilac.CleanMenuBar/Data/Library/Preferences/com.atilac.CleanMenuBar
OUT=docs/app-store/screenshots
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

test -x "$APP" || { echo "build the app first: xcodebuild ... -derivedDataPath build build"; exit 1; }

# Finds the settings window by id, so nothing of the desktop behind it is caught.
cat > "$WORK/winid.swift" <<'SWIFT'
import AppKit
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
    as? [[String: Any]] ?? []
for w in list {
    guard let owner = w[kCGWindowOwnerName as String] as? String, owner == "CleanMenuBar",
          let number = w[kCGWindowNumber as String] as? Int,
          let bounds = w[kCGWindowBounds as String] as? [String: Any],
          let h = bounds["Height"] as? Double, h > 100 else { continue }
    print(number); exit(0)
}
exit(1)
SWIFT
swiftc -O "$WORK/winid.swift" -o "$WORK/winid"

for LANGUAGE in en pt-BR es fr de ja zh-Hans zh-Hant ru; do
    SHOTS="$WORK/$LANGUAGE"
    mkdir -p "$SHOTS"

    pkill -f "CleanMenuBar.app/Contents/MacOS/CleanMenuBar" 2>/dev/null || true
    sleep 1
    for KEY in separatorsHidden alwaysHiddenSectionEnabled autoCollapse \
               hoverToExpand restoreLastState useFullStatusBarOnExpand; do
        defaults write "$DOMAIN" $KEY -bool false
    done
    # Set explicitly rather than left to whatever this machine happens to have:
    # an unset preference leaked the host's value into the frames, and Russian
    # ended up showing a switch off that every other language showed on.
    #
    # Both switches on: the frames show a configured app, not a fresh install.
    # The app itself ships with launch-at-login off — registering a login item
    # unasked is what App Store review objects to — but a screenshot of an app
    # nobody has set up yet sells nothing.
    defaults write "$DOMAIN" launchAtLogin -bool true
    defaults delete "$DOMAIN" forcedLanguage 2>/dev/null || true
    defaults write "$DOMAIN" AppleLanguages -array "$LANGUAGE"

    # The menu bar strips, in both states.
    defaults write "$DOMAIN" showSettingsAtLaunch -bool false
    # Wait for the app to announce itself instead of sleeping a fixed amount:
    # SIGUSR1 below terminates it outright until the handler is armed, which on
    # a busy machine happens after any sleep short enough to be worth using.
    LAUNCH_LOG=$(mktemp)
    "$APP" > "$LAUNCH_LOG" 2>&1 &
    for _ in $(seq 60); do
        grep -q "^READY" "$LAUNCH_LOG" && break
        sleep 0.5
    done
    grep -q "^READY" "$LAUNCH_LOG" || { echo "the app never became ready"; exit 1; }
    PID=$(pgrep -f "CleanMenuBar.app/Contents/MacOS/CleanMenuBar" | head -1)
    # Framed on the icons themselves. The region stops before x=1500 because
    # macOS draws the screen-recording indicator at the right edge while
    # screencapture runs, and it lands in the frame otherwise.
    #
    # Turn the menu bar clock off before capturing: it renders in the system's
    # language, so a Japanese listing would carry an English date in every frame.
    screencapture -x -R 1064,0,426,32 "$SHOTS/bar_expanded.png"
    kill -USR1 "$PID"; sleep 2
    screencapture -x -R 1064,0,426,32 "$SHOTS/bar_collapsed.png"
    pkill -f "CleanMenuBar.app/Contents/MacOS/CleanMenuBar" 2>/dev/null || true
    rm -f "$LAUNCH_LOG"
    sleep 1

    # The settings window, two tabs.
    defaults write "$DOMAIN" showSettingsAtLaunch -bool true
    for TAB in general howitworks; do
        pkill -f "CleanMenuBar.app/Contents/MacOS/CleanMenuBar" 2>/dev/null || true
        sleep 1
        CMB_OPEN_TAB=$TAB "$APP" >/dev/null 2>&1 &
        sleep 4
        WID=$("$WORK/winid") || { echo "$LANGUAGE: settings window not found"; exit 1; }
        screencapture -x -o -l"$WID" "$SHOTS/win_$TAB.png"
    done
    pkill -f "CleanMenuBar.app/Contents/MacOS/CleanMenuBar" 2>/dev/null || true

    DEST="$OUT/$LANGUAGE"
    mkdir -p "$DEST"
    swift Tools/BuildScreenshots.swift "$SHOTS" "$DEST" "$LANGUAGE" >/dev/null
    echo "  $LANGUAGE"
done

defaults delete "$DOMAIN" AppleLanguages 2>/dev/null || true
echo
echo "9 languages x 3 frames in $OUT/"
