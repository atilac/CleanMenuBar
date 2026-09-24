# Mac App Store submission notes

Everything App Store Connect asks that is not obvious from the app itself.
Kept here so the answers stay consistent between submissions.

## Identity

| Field | Value |
|---|---|
| Seller / legal entity | MONOBIT (ATILA VITAL CAVALCANTE DA SILVA LTDA) |
| Company Name (macOS listing) | Monobit |
| Store name | CleanMenuBar: Hide Icons |
| Team ID | NP9YTUN8LD |
| Bundle ID | com.monobit.CleanMenuBar |
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

The marketing version matches the GitHub release exactly — **0.1.3** in both
places — so a bug report naming a version points at one known build regardless
of where the user got the app.

The *build* number is the one thing that legitimately differs. App Store Connect
refuses a build number it has already seen, so an upload that gets rejected and
resubmitted has to increment it while the marketing version stands still.
0.1.3 carries build 4 in both places; the first resubmission, should there be
one, would be build 5 under the same 0.1.3.

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

Checked against the App Store Connect API on 2026-09-24: the team holds one
certificate (Developer ID Application, expiring 2031-09-16), has **no
registered App IDs**, and **no app records**. So all four steps below are
outstanding, in this order — step 4 cannot be done before step 3.

### A note that applies to both certificates

The CSRs here were generated with `openssl`, which means the private key sits in
a file rather than in the keychain. This matters: downloading the `.cer` and
double-clicking it installs a certificate with no matching key, and an identity
without its key cannot sign anything — `security find-identity` will not list
it, and the build script's check will keep failing with the certificate
apparently installed.

The fix is the same one used for the Developer ID certificate: pair the
downloaded `.cer` with its `.key` into a `.p12` and import that. Download both
`.cer` files, leave them in `~/Downloads`, and run the pairing below.

### 1. Apple Distribution certificate

1. Open <https://developer.apple.com/account/resources/certificates/list>
2. Click **+**
3. Under *Software*, choose **Apple Distribution** — the description reads "Sign
   your apps for submission to the App Store or for Ad Hoc distribution". Do not
   pick *Developer ID Application*; that one is already here and is for
   distribution outside the store.
4. **Continue** › **Choose File** › `~/Developer/CleanMenuBar-signing/appleDistribution.csr`
   (in the file dialog, ⇧⌘G pastes a path)
5. **Continue** › **Download**. It lands as `distribution.cer`.

### 2. Mac Installer Distribution certificate

Same page, same **+**, but choose **Mac Installer Distribution** — "This
certificate is used to sign your app's Installer Package for submission to the
Mac App Store". Upload
`~/Developer/CleanMenuBar-signing/macInstaller.csr` and download the `.cer`.

This one signs the package, not the app. Both are required: the app is signed
with Apple Distribution, wrapped in a `.pkg`, and the `.pkg` is signed with this.

### 3. Register the App ID

App Store Connect will not offer a bundle ID that is not registered here first,
and the dropdown in step 4 simply comes up empty without it.

1. Open <https://developer.apple.com/account/resources/identifiers/list>
2. **+** › **App IDs** › **Continue** › type **App** › **Continue**
3. Description: `CleanMenuBar`
4. Bundle ID: **Explicit**, `com.monobit.CleanMenuBar`
5. Capabilities: leave every box unchecked. App Sandbox is declared in the
   entitlements file, not here, and the app uses nothing that needs enabling.
6. **Continue** › **Register**

### 4. Create the app record

1. Open <https://appstoreconnect.apple.com/apps>
2. **+** › **New App**
3. Platforms: **macOS** only
4. Company Name: `Monobit` — this field appears only for macOS apps. It is the
   name the Mac App Store shows on the product page, and it does not have to be
   the registered entity: the full legal name reaches buyers through the seller
   information, which comes from the account rather than from here. Worth
   getting right the first time, since changing it later tends to mean a support
   request rather than a free edit.
5. Name: `CleanMenuBar: Hide Icons`. Plain `CleanMenuBar` is reserved by
   someone who never shipped under it — a search of the Mac App Store turns up
   no such app — and Apple holds a reserved name for as long as the record
   exists. The trademark claim the error offers is not a route without a
   registered mark.

   Only the storefront name changed. The app is still CleanMenuBar in the Dock,
   in the repository, on the site and in the bundle identifier, and the store
   name reads the same to anyone scanning it.
6. Primary Language: **English (U.S.)** — see the Identity section above for why
   this is not Portuguese
7. Bundle ID: `com.monobit.CleanMenuBar`, which appears in the dropdown a few
   minutes after step 3
8. SKU: `cleanmenubar` — internal only, never shown to anyone
9. User Access: **Full Access**
10. **Create**

### 5. Build and upload

Once both certificates are in the keychain and the record exists:

```sh
CMB_BUILD=4 Tools/build-appstore-pkg.sh
xcrun altool --upload-app -t macos -f dist-appstore/CleanMenuBar.pkg \
  --apiKey ABX25DD23T --apiIssuer 0f395b89-aeaf-403e-ad15-c3d5558be79b
```

`altool` reads the key from `~/.appstoreconnect/private_keys/`; the key is now
in place there.

The API key is read-only. It can list certificates, identifiers, apps and
builds, and it can upload — but it cannot edit the version string, create a
provisioning profile, or sign in the cloud. So the version number has to be
changed in the web interface, and the export relies on the Apple ID signed into
Xcode instead. Raising the key's role in *Users and Access › Integrations*
would remove both restrictions.

### The two API keys

Neither is named after a project, because neither is scoped to one: a key
belongs to the team and reaches every app in it.

| Key | Access | What breaks if it is revoked |
|---|---|---|
| `ABX25DD23T` | Developer | Notarisation in CI — it is in the repository secrets |
| `H62S9X5DTG` | App Manager | Pushing listing text and screenshots from here |

Both live in `~/Developer/CleanMenuBar-signing/`, alongside the certificates.
That directory name is a leftover: nothing in it is specific to this app.

Apple serves a `.p8` once and never again, so losing one means revoking,
generating a replacement, and updating the GitHub secrets.

### Trader status

App Store Connect will not accept a submission until *Business › Trader Status*
is filled in — an EU Digital Services Act requirement for anything new since
October 2024. As a registered company the answer is that MONOBIT is a trader,
and the contact details given there become publicly visible on the EU
storefronts.

### 6. Fill the listing

Text from `docs/app-store/<locale>.md`, screenshots from
`docs/app-store/screenshots/<locale>/`, URLs and questionnaire answers from the
top of this file.

## What still has to be decided

- **Sandbox vs. the hiding technique**: the technique uses only public
  `NSStatusItem` API and stays inside the sandbox, but macOS 27 shipped no
  supported API for menu bar management. Review could still object. If it does,
  distribution outside the App Store via Developer ID is unaffected.
- **Price**: the listing is currently set up as free. A paid tier would mean
  revising the site line that calls the app free and open source, since the
  GitHub build would stay free either way.
