# Mac App Store submission notes

Everything App Store Connect asks that is not obvious from the app itself.
Kept here so the answers stay consistent between submissions.

## Identity

| Field | Value |
|---|---|
| Seller / legal entity | MONOBIT (ATILA VITAL CAVALCANTE DA SILVA LTDA) |
| Team ID | NP9YTUN8LD |
| Bundle ID | com.atilac.CleanMenuBar |
| Support URL | https://monobit.com.br/CleanMenuBar |
| Privacy Policy URL | https://monobit.com.br/CleanMenuBar/privacy |
| Category | Utilities |
| Price | Free |

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

## What still has to be decided

- **Screenshots**: the App Store requires at least one 2880×1800 or 2560×1600
  screenshot. A menu bar app is hard to show — the interesting part is a 40pt
  strip at the top of the screen. Before/after pairs of the menu bar, cropped
  and enlarged, communicate it better than a full desktop shot.
- **Sandbox vs. the hiding technique**: the technique uses only public
  `NSStatusItem` API and stays inside the sandbox, but macOS 27 shipped no
  supported API for menu bar management. Review could still object. If it does,
  distribution outside the App Store via Developer ID is unaffected.
