<div align="center">

<img src="CleanMenuBar/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="128" alt="CleanMenuBar icon">

# CleanMenuBar

**Hide the menu bar icons you don't want to look at — on macOS 27.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS 27+](https://img.shields.io/badge/macOS-27%2B-black.svg)](#requirements)

</div>

---

## Why this exists

macOS 27 rebuilt the menu bar as a single window and broke Hidden Bar, the app
I used to hide icons. It relied on a technique that stopped working.

CleanMenuBar is derived from Hidden Bar with an adapted mechanism, built and
measured directly on macOS 27 Golden Gate one day after its public release
(14 September 2026).

## How macOS 27 broke the old approach

Every menu bar hider used to give one of its own status items an enormous
length. The bar packs icons right-to-left, so an oversized item shoved
everything to its left off the screen. On macOS 27 that no longer happens: the
bar does not reflow around an oversized item, and any item whose length reaches
**half the display width** is dropped outright.

Measured on macOS 27.0, on a 1512pt display (so the cliff sits at 756pt):

| Item length | What actually happens |
|---|---|
| 10000 | Renders 5016pt wide, yields its slot, moves no neighbour at all |
| 730 | Not drawn anywhere on screen — but icons to its left *do* disappear |
| 500 | Draws, and icons to its left spill into the system's native overflow |

The consequence is awkward and it shapes the whole design: **the item that
pushes can never be the item you click.** Hiding requires the system to discard
the item; being clickable requires it to survive. So CleanMenuBar uses two:

```
[ …icons you want hidden… ]  [ pusher ]  [ arrow ]  [ …always visible… ]
```

The pusher inflates to just under the cliff and vanishes, taking everything to
its left with it. The arrow sits to its right, outside the blast radius, and
stays where you can click it.

## Setting up

1. Hold **⌘** and drag the icons you want hidden so they sit to the **left** of
   the CleanMenuBar separator.
2. Anything to the **right** of the separator stays visible at all times.
3. Click the arrow to collapse or expand, or press **⌃⌥⌘C** from anywhere.
4. Right-click the arrow or the separator for settings.
5. Once everything is arranged, turn on **Hide the separators** to leave only
   the arrow on screen.

The positions survive quitting and relaunching — macOS remembers them per item.

## Features

| | |
|---|---|
| Hide and reveal | Click, global shortcut (**⌃⌥⌘C**), or hover |
| Always-hidden section | A second span that stays hidden even when expanded |
| Auto-collapse | After 5, 10, 15, 30 or 60 seconds |
| Hover to expand | Opens after a short dwell in the menu bar |
| Launch at login | Via `SMAppService` |
| Hide separators | Leave only the arrow once you are set up |
| Use the full menu bar | Frees the space the frontmost app's menus occupy |

Shortcut conflicts are flagged in settings — both the system-reserved kind
(⌥⌘H is Hide Others, and would fire both actions) and the app-level kind
(⌥⌘C is Copy Style in TextEdit, Pages, Keynote and Mail).

### Planned

Listed in the settings window as disabled rows, so the gaps are visible rather
than quietly missing: keeping CleanMenuBar in the Dock, restoring the last state
at launch, and a visual guide in the settings window. Contributions welcome —
see [CONTRIBUTING.md](CONTRIBUTING.md).

## Requirements

macOS 27 or later, which means Apple Silicon: macOS 27 does not run on Intel
Macs, so the build produces an arm64 binary and nothing else.

macOS 26 is deliberately not supported. The hiding mechanism here is calibrated
against behaviour macOS 27 introduced, and has never been tested on 26 — where
the older technique still works and Hidden Bar still does the job. Claiming 26
without testing it would be a promise this project cannot keep.

## Building

```sh
git clone https://github.com/atilac/CleanMenuBar.git
cd CleanMenuBar
open CleanMenuBar.xcodeproj
```

Or from the command line:

```sh
xcodebuild -project CleanMenuBar.xcodeproj -scheme CleanMenuBar \
           -configuration Debug -derivedDataPath build build
```

No dependency manager, no code generation. The app target uses an Xcode
synchronized folder group, so files added under `CleanMenuBar/` are picked up
automatically and `project.pbxproj` stays out of your merge conflicts.

Regenerate the icon after editing `Tools/GenerateAppIcon.swift`:

```sh
swift Tools/GenerateAppIcon.swift
```

## Debugging the menu bar

The menu bar cannot be driven by UI automation, which makes this app unusually
hard to test. Two hooks exist for that:

```sh
kill -USR1 <pid>    # toggle collapsed/expanded
kill -USR2 <pid>    # dump what is actually in effect
```

`USR2` prints the real length, visibility and image state of every item, plus
the activation policy, hot key registration and pointer position — the values
the system is really using, not what is stored in preferences. If you are
debugging a hiding regression on a new macOS release, start there and include
the output in the issue.

```
CMB_FORCE_LEN=500   # override the push distance, to probe the drop threshold
```

## Design constraints

- **Public API only.** No private frameworks, no swizzling, no undocumented
  selectors.
- **Sandbox-clean.** The global shortcut uses Carbon's `RegisterEventHotKey`,
  which needs no Accessibility permission, and hover uses a mouse-only global
  monitor, which needs none either. Nothing here requires Screen Recording.
- **Accessory app.** No Dock icon, no main window, no launch delay.

## Known limits

The push is capped at half the width of the **narrowest** attached display, so a
very wide external monitor can have more menu bar than one item can clear. This
is the same wide-display problem the upstream Hidden Bar work ran into, and it
is the honest ceiling of the technique.

Whether Apple will accept this on the Mac App Store is unresolved. macOS 27
shipped no supported API for third-party menu bar management, so this is a
workaround, however well-behaved.

## Credits

CleanMenuBar stands on [Hidden Bar](https://github.com/dwarvesf/hidden) by
Dwarves Foundation. Its menu structure, preference set and user-facing strings
are derived from commit
[`0dde4b6`](https://github.com/dwarvesf/hidden/commit/0dde4b6882144309263ac465375971a5c39b492d)
(16 June 2026 — the main branch after v1.10), used under the MIT License. See
[NOTICE](NOTICE).

Thank you to Dwarves Foundation and to everyone who built and maintained Hidden
Bar over six years. They kept a small, focused, genuinely free tool alive, and
this app has its shape because of theirs. The hiding mechanism here had to be
rewritten — macOS 27 removed the behaviour every menu bar hider depended on —
but the design it replaces was theirs first.

No code from [Ice](https://github.com/jordanbaird/Ice) was used or consulted —
Ice is GPL-3.0, which is incompatible with this project's MIT licensing.

## Privacy

CleanMenuBar collects nothing and has no network entitlement, so it cannot
transmit anything even if its code tried to. Settings stay in its own sandbox
container. Full policy: [PRIVACY.md](PRIVACY.md), published at
https://monobit.com.br/cleanmenubar/en/privacy.html

## Warranty

None. As the MIT licence puts it, the software is provided "as is", without
warranty of any kind, and the authors are not liable for any claim or damage
arising from it. The full text ships inside the app — see **About → Licenses** —
as well as in [LICENSE](LICENSE).

## License

[MIT](LICENSE) — Copyright (c) 2026 MONOBIT (ATILA VITAL CAVALCANTE DA SILVA LTDA).

The app bundle carries both `LICENSE` and `NOTICE` in `Contents/Resources`, so
every copy distributed satisfies the attribution both this project and Hidden
Bar require.
