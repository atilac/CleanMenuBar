# Contributing to CleanMenuBar

Thanks for wanting to help. This project exists because the existing menu bar
hiders stopped working reliably on recent macOS releases, so correctness on the
current OS matters more here than feature count.

## Getting started

```sh
git clone https://github.com/atilac/CleanMenuBar.git
cd CleanMenuBar
open CleanMenuBar.xcodeproj
```

Requirements: macOS 27 or later, Xcode 27 or later.

There is no dependency manager and no code generation step — open the project
and build. The app target uses an Xcode *synchronized folder group*, which means
files you add inside `CleanMenuBar/` are picked up automatically and you never
have to touch `project.pbxproj`. That keeps merge conflicts out of the project
file entirely.

Command-line build:

```sh
xcodebuild -project CleanMenuBar.xcodeproj -scheme CleanMenuBar \
           -configuration Debug -derivedDataPath build build
```

## Lab mode

The menu bar is difficult to test through normal UI automation, so the app has a
scripted mode that cycles through every visibility state on a timer:

```sh
CMB_LAB=1 ./build/Build/Products/Debug/CleanMenuBar.app/Contents/MacOS/CleanMenuBar
```

It prints the real on-screen frame of each status item at every transition. If
you are debugging a hiding regression on a new macOS version, start here — and
please include that output in the issue.

## Ground rules

- **Public API only.** No private frameworks, no swizzling of AppKit internals,
  no undocumented selectors. The app has to stay shippable on the Mac App Store,
  which means it also has to keep working inside the App Sandbox.
- **Keep it an accessory app.** No Dock icon, no main window, no launch delay.
- Match the surrounding style. The project builds with Swift 6 language mode and
  `SWIFT_STRICT_CONCURRENCY=complete`; new code should compile without warnings.

## Reporting a hiding bug

Menu bar behaviour varies by display setup more than anything else. Please include:

- macOS version (`sw_vers`) and Mac model (`sysctl -n hw.model`)
- Number of displays, and whether the affected one has a notch
- Output of lab mode (above)
- A screenshot of the menu bar in the broken state

## License

By contributing you agree that your contributions are licensed under the MIT
License, the same terms that cover the rest of the project.
