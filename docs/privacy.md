# Privacy Policy — CleanMenuBar

**Last updated:** 15 September 2026
**Applies to:** CleanMenuBar for macOS, all versions
**Published at:** https://monobit.com.br/CleanMenuBar/privacy

## The short version

CleanMenuBar collects nothing, sends nothing, and has no servers.

That is not a policy choice that could quietly change — it is what the app is
technically capable of. CleanMenuBar runs inside Apple's App Sandbox with no
network entitlement, so it cannot open a network connection even if its code
tried to.

## What the app stores

Your settings — the language, the shortcut, whether auto-collapse is on and
after how long — are written to macOS's standard preferences store, inside the
app's own sandbox container:

```
~/Library/Containers/com.atilac.CleanMenuBar/
```

This stays on your Mac. It is not transmitted, not backed up by us, and not
readable by us. Deleting the app and that folder removes everything CleanMenuBar
has ever written.

macOS separately remembers where you dragged your menu bar icons. That is the
system's own record, not ours, and it lives outside the app.

## What the app does not do

- No analytics, telemetry, crash reporting or usage statistics
- No accounts, logins or identifiers
- No advertising, and no data shared with advertisers or anyone else
- No network requests of any kind
- No access to your files, contacts, camera, microphone, or location

## Permissions

CleanMenuBar requests **no** special permissions. It needs neither Accessibility
nor Screen Recording, which sets it apart from most menu bar tools — the global
shortcut uses an API that works without them, and the app never reads the screen.

If macOS ever prompts you for a permission on CleanMenuBar's behalf, treat that
as a bug and report it.

## Children

CleanMenuBar is not directed at children and collects no data from anyone,
regardless of age.

## The source is public

You do not have to take any of this on trust. The complete source is published
under the MIT Licence at https://github.com/atilac/CleanMenuBar, including the
entitlements file that declares what the app is allowed to do.

## Changes

If this policy ever changes, the revised version will be published at the URL
above with a new date. Since the app collects nothing, any change that mattered
would require a new release — and the source diff would show it.

## Contact

MONOBIT (ATILA VITAL CAVALCANTE DA SILVA LTDA)
apps@monobit.com.br
