# App Store — en

**Version 0.1.3** — same number as the GitHub release, deliberately: one
number, one binary, one set of changes, wherever someone finds the app.

## Name (30)

CleanMenuBar: Hide Icons

## Subtitle (30)

Tidy up your menu bar

## Keywords (100)

hide,conceal,icons,menubar,status bar,declutter,tidy,productivity,notch,shortcut,minimal

## Promotional text (170)

Hide the icons you never use and reveal them when you need them. No permissions, no data collection, no network. Open source under the MIT License.

## Description (4000)

Too many icons in your menu bar? CleanMenuBar hides the ones you don't want to see and reveals them when you need them.

HOW IT WORKS

Two items appear in your menu bar: a thin separator "|" and an arrow ">".

Hold ⌘ and drag the icons you want hidden to the left of the separator "|". Anything to the right of it stays visible at all times. Click the arrow ">" to collapse or "<" to expand — or press ⌃⌥⌘C from anywhere.

Once everything is arranged, turn on "Hide the separators" in settings and only the arrow remains on screen.

Positions survive relaunching. macOS remembers where each icon sits.

FEATURES

• Hide and reveal by click, global shortcut, or just hovering
• An always-hidden section, for icons you never want to see
• Auto-collapse after 5, 10, 15, 30 or 60 seconds
• Restore the last state at launch
• Launch at login
• Nine languages

NO PERMISSIONS

CleanMenuBar asks for no special permissions. It needs neither Accessibility nor Screen Recording — unusual for a menu bar tool, and possible because the global shortcut uses an API that works without them and the app never reads the screen.

It has no network entitlement either. It could not transmit anything even if its code tried to. Nothing is read outside its own sandbox container.

REQUIRES macOS 27

macOS 27 rebuilt the menu bar as a single window, and the technique some apps use stopped working. CleanMenuBar was built and measured directly on macOS 27, one day after its public release.

Earlier versions of macOS are not supported — and do not need to be: there the older technique still works.

Because macOS 27 does not run on Intel Macs, CleanMenuBar requires Apple Silicon.

OPEN SOURCE

The complete source is published under the MIT License, including the file that declares exactly what the app is allowed to do. You do not have to believe any of the above — you can check.

github.com/atilac/CleanMenuBar

THANKS

CleanMenuBar stands on Hidden Bar by Dwarves Foundation, used under the MIT License. Its menus, settings and wording come from theirs. Thank you to everyone who kept it alive over six years.

## What's New

First public release of CleanMenuBar.
