# App Store screenshots

Three frames at 2880×1800, the size the Mac App Store accepts.

    01-before-after.png     the menu bar with and without the icons hidden
    02-settings.png         the settings window
    03-how-it-works.png     setup steps and the macOS 27 note

## Regenerating

`sources/` holds the raw captures; `Tools/BuildScreenshots.swift` composes them.

```sh
swift Tools/BuildScreenshots.swift \
      docs/app-store/screenshots/sources \
      docs/app-store/screenshots
```

Recapture the sources when the interface changes:

- `bar_expanded.png`, `bar_collapsed.png` — `screencapture -x -R 812,0,676,38`,
  once in each state. The region ends before x=1500 on purpose: macOS draws the
  screen-recording indicator at the right edge while `screencapture` runs, and
  it lands in the frame otherwise.
- `win_general.png`, `win_howitworks.png` — capture by window id, not by
  rectangle, so nothing of the desktop behind it is included.

Set the app to English and every preference to its default first. A frame
showing "Português (Brasil)" selected in an English window, or a toggle left on
from testing, reads as a bug in the app.

## Why these three

A menu bar app is awkward to show: the part that matters is a 40pt strip at the
top of the screen, and a full desktop capture buries it. Each frame states one
claim in type and shows the evidence enlarged beneath it. The claim and the
evidence have to match — a headline promising "no permissions" over a window of
setup steps asks the reader to take it on faith while looking at something else.
