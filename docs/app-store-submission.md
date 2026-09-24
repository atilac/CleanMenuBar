# Mac App Store submission notes

Everything App Store Connect asks that is not obvious from the app itself.
Kept here so the answers stay consistent between submissions.

## Identity

| Field | Value |
|---|---|
| Seller / legal entity | MONOBIT (ATILA VITAL CAVALCANTE DA SILVA LTDA) |
| Team ID | NP9YTUN8LD |
| Bundle ID | com.atilac.CleanMenuBar |
| **Primary language** | **English (U.S.)** |
| Category | Utilities |
| Price | Free |

### URLs

Review is conducted in English, so everything a reviewer opens has to resolve to
English. The site's root is Portuguese — these all carry the `/en/` prefix on
purpose, and none of them should be shortened.

| Field | URL |
|---|---|
| Support URL | https://monobit.com.br/cleanmenubar/en/ |
| Marketing URL | https://monobit.com.br/cleanmenubar/en/ |
| Privacy Policy URL | https://monobit.com.br/cleanmenubar/en/privacy.html |
| Terms of Use (EULA) | https://monobit.com.br/cleanmenubar/en/terms.html |

**Primary language must be English (U.S.)**, not Portuguese. It decides which
listing a reviewer reads and which one users see when their own locale has no
translation. Portuguese, Spanish and the rest are added afterwards as additional
localisations, each of which can carry its own URLs:

| Locale | Privacy | Support |
|---|---|---|
| pt-BR | `/privacy.html` | `/` |
| es | `/es/privacy.html` | `/es/` |
| fr, de, ja, zh-Hans, zh-Hant, ru | `/<code>/privacy.html` | `/<code>/` |

### End User Licence Agreement

Apple's standard EULA applies unless a custom one is supplied. It is sufficient
here: the app is free, collects nothing, and the MIT licence — which ships
inside the bundle at **About → Licenses** — already disclaims warranty and
liability. The Terms of Use page above is published for users rather than
required by Apple; link it only if App Store Connect asks for a custom EULA.

## App Privacy questionnaire

The form is mandatory even for apps that collect nothing, and answering it
wrongly is worse than answering it slowly. Every answer below is **No**, and
each one is true by construction rather than by policy: the app has no network
entitlement, so it could not transmit anything if it tried.

> **Do you or your third-party partners collect data from this app?**
> **No**

That single answer closes the rest of the form. For the record, were it asked
item by item: no contact info, no health data, no financial info, no location,
no contacts, no user content, no search history, no browsing history, no
identifiers, no usage data, no diagnostics, no purchases, no sensitive info.

There are no third-party SDKs, no analytics, and no advertising libraries — the
app links only Apple frameworks.

## Export compliance

> **Does your app use encryption?**
> **No**

The app implements no encryption and calls no cryptographic APIs. It has no
network access at all, so there is nothing to encrypt in transit.

`ITSAppUsesNonExemptEncryption` can be set to `false` in Info.plist to skip this
question on every upload.

## Sandbox and entitlements

Required for App Store distribution and already in place:

```
com.apple.security.app-sandbox                    true
com.apple.security.files.user-selected.read-only  true
```

Notably **absent**, and worth stating in the review notes because menu bar apps
are usually assumed to need them:

- No Accessibility permission — the global shortcut uses `RegisterEventHotKey`,
  which works without it
- No Screen Recording — the app never reads the screen
- No network entitlement

## Review notes

Suggested text for the reviewer, since the app's behaviour is unusual and a
reviewer who does not know the setup step may conclude it does nothing:

> CleanMenuBar hides menu bar icons. After launch, two items appear in the menu
> bar: a thin separator and an arrow. Hold Command and drag any menu bar icon so
> that it sits to the LEFT of the separator, then click the arrow. The icons to
> the left of the separator are hidden; clicking the arrow again reveals them.
> The keyboard shortcut Control-Option-Command-C does the same thing.
>
> The app requires no permissions, makes no network requests, and collects no
> data. Source: https://github.com/atilac/CleanMenuBar
>
> CleanMenuBar ships in nine languages and follows the system language at
> launch, so it will appear in English on an English test system. If you need to
> see another language, Settings › General › Language lets you pick one; the app
> restarts to apply it.

## Version numbering

The marketing version matches the GitHub release exactly — **0.1.2** in both
places — so a bug report naming a version points at one known build regardless
of where the user got the app.

The *build* number is the one thing that legitimately differs. App Store Connect
refuses a build number it has already seen, so an upload that gets rejected and
resubmitted has to increment it while the marketing version stands still. The
GitHub v0.1.2 tag carries build 3; the first App Store upload of 0.1.2 carries
build 4, which also picks up `LSApplicationCategoryType` — a key App Store
Connect requires and that does nothing in a Developer ID build.

## Screenshots

Done: `docs/app-store/screenshots/<locale>/`, three 2880×1800 frames per locale,
nine locales. Each pair shows the same menu bar before and after hiding, cropped
to the strip that matters and enlarged, because a full desktop shot renders the
subject a few pixels tall.

The frames were captured with *Launch at login* and *Show this window at start*
both switched on. That is deliberate and does not match the shipping defaults —
it shows the settings window in the state a settled user ends up in, rather than
mid-onboarding with the login suggestion card still up.

## Remaining steps

Two certificates and an app record are all that stand between here and an
upload. Everything else is built and verified.

1. **Apple Distribution certificate** — at developer.apple.com, Certificates ›
   `+` › *Apple Distribution*, upload
   `~/Developer/CleanMenuBar-signing/appleDistribution.csr`. Download the `.cer`
   and double-click it.
2. **Mac Installer Distribution certificate** — same place, *Mac Installer
   Distribution*, upload
   `~/Developer/CleanMenuBar-signing/macInstaller.csr`. This one signs the
   `.pkg`, not the app; without it the package is unsigned and the upload fails.
3. **App record** — App Store Connect › Apps › `+`, platform **macOS**, primary
   language **English (U.S.)**, bundle ID `com.atilac.CleanMenuBar`, SKU
   `cleanmenubar`.
4. **Build the package** — `Tools/build-appstore-pkg.sh`. It refuses to run
   until both certificates are in the keychain, so a missing one fails loudly
   rather than producing a package that dies at upload.
5. **Upload** — `xcrun altool --upload-app -t macos -f dist/CleanMenuBar.pkg
   --apiKey ABX25DD23T --apiIssuer <issuer id>`, with `AuthKey_ABX25DD23T.p8`
   in `~/.appstoreconnect/private_keys/`.
6. **Fill the listing** — text from `docs/app-store/<locale>.md`, screenshots
   from `docs/app-store/screenshots/<locale>/`, URLs and questionnaire answers
   from this file.

## What still has to be decided

- **Sandbox vs. the hiding technique**: the technique uses only public
  `NSStatusItem` API and stays inside the sandbox, but macOS 27 shipped no
  supported API for menu bar management. Review could still object. If it does,
  distribution outside the App Store via Developer ID is unaffected.
- **Price**: the listing is currently set up as free. A paid tier would mean
  revising the site line that calls the app free and open source, since the
  GitHub build would stay free either way.
