# Deploying Yogi from Xcode

Requires macOS with Xcode 15.4+ and an Apple Developer account ($99/yr) for anything
beyond the simulator. No other tooling — the Xcode project is committed.

For credentials and backend setup, see `CONNECT.md`. You can do everything through step 5
here with no credentials at all — the app runs on local heuristics and sample data.

---

## 1. Open it

Double-click **`ios/Yogi/Yogi.xcodeproj`**. That is the whole step — the project file is in
the repo, so there is no toolchain to install first.

Xcode resolves the Supabase package from GitHub on first open. Wait for the progress bar in
the toolbar to finish before building, or the first build fails on a missing module.

Adding files later works normally: File → Add Files, or just drag them in. Xcode owns the
project file from here.

<details>
<summary>Regenerating the project from scratch</summary>

`tools/generate_xcodeproj.py` wrote it and can rewrite it if it ever gets mangled:

```
python3 tools/generate_xcodeproj.py
```

That rebuilds the project, both schemes, and the Info.plist and entitlements files from the
source tree. It overwrites the project file, so anything you added through Xcode's UI in the
meantime is lost — the script is a repair tool, not part of the normal loop.
</details>

## 2. Signing — both targets

Xcode will show a red signing error until you pick a team. Do it in the UI:

1. Click **Yogi** at the top of the file navigator (the blue project icon).
2. In the target list, select **Yogi** → **Signing & Capabilities** tab.
3. Set **Team** to your account. Leave "Automatically manage signing" ticked.
4. Select the **YogiShare** target in the same list and set the same team.

Both targets already declare their capabilities (Sign in with Apple and App Groups on the
app, App Groups on the extension), so they appear in that tab with no setup.

If Xcode reports the bundle ID is taken, click the bundle identifier field and change the
prefix on both targets — then change the App Group to match in three places, or shared links
will silently vanish:

- both targets' **App Groups** rows in Signing & Capabilities
- `Yogi/Shared/ShareInbox.swift` → `YogiAppGroup.identifier`

If the App Groups row shows a red error, click the refresh (circular arrow) button; Xcode
registers the group for you if your account has permission.

## 3. Run in the simulator

Pick any iPhone running iOS 17+ and press ⌘R.

The `Yogi` scheme already has `Yogi.storekit` attached, so the paywall shows the £29.99/yr
product and purchases complete against the local StoreKit file. Nothing is charged and no
App Store Connect record is needed.

## 4. Run on your phone

1. Connect the phone. On the phone: Settings → Privacy & Security → Developer Mode → on,
   then reboot.
2. Pick the device in Xcode's destination menu, press ⌘R.
3. First run only: on the phone, Settings → General → VPN & Device Management → tap your
   developer certificate → Trust.

A free (non-paid) Apple ID can sign to a device, but the provisioning profile expires after
7 days and App Groups are not available — the share extension will not work.

## 5. Test the share extension

In Safari on the device or simulator, open any page → Share → scroll the bottom action row
→ **Add to Yogi**. If it is not there, tap "Edit Actions…" and enable it.

To debug it with breakpoints: Product → Scheme → YogiShare, press ⌘R, and pick Safari when
Xcode asks for a host app.

Two things that confuse everyone:

- The save appears in Yogi when you next **open Yogi**, not the instant you share. The
  extension only queues; the app does the import. That is deliberate — see the README.
- After changing extension code, delete the app from the device before reinstalling. iOS
  caches extension registrations aggressively.

## 6. Add the backend (optional until TestFlight)

Create `ios/Yogi/Yogi/Resources/Yogi.local.xcconfig` (git-ignored, and already
`#include?`'d by the checked-in xcconfig) with:

```
SUPABASE_URL = https:/$()/YOUR-REF.supabase.co
SUPABASE_ANON_KEY = sb_publishable_...
```

The `$()` is required — xcconfig reads a bare `//` as a comment. Full backend setup is in
`CONNECT.md`.

## 7. Archive and upload to TestFlight

First create the app record in App Store Connect with bundle ID `com.sourcedai.yogi`
(My Apps → + → New App). The upload is rejected without it.

Then:

1. Bump the build number: project → Yogi target → General → **Build**. Every upload needs a
   build number higher than the last one for that version string. Do it on both targets.
2. Destination menu → **Any iOS Device (arm64)**. Archive is greyed out on a simulator.
3. Product → Archive.
4. In the Organizer that opens: Distribute App → App Store Connect → Upload → Next through
   the defaults → Upload.

Export compliance is already declared (`ITSAppUsesNonExemptEncryption: false`), so there is
no encryption questionnaire.

Processing takes 5–30 minutes. The build then appears under TestFlight, ready for internal
testers immediately; external testers need a review pass.

## 8. Submitting to the App Store

Beyond TestFlight you also need: screenshots at 6.7" and 6.5", a privacy policy URL, App
Privacy answers (this app collects saved content and, if you enable it, location), and a
demo account for review. If subscriptions are live, review will not pass until
`com.sourcedai.yogi.pro.yearly` is approved alongside the build.

---

## When it fails

| Symptom | Cause |
|---|---|
| `No such module 'Supabase'` | Package still resolving, or resolution failed. File → Packages → Resolve Package Versions. |
| Signing settings vanished | You re-ran `tools/generate_xcodeproj.py`, which overwrites the project. Set the team again in Xcode. |
| `Failed to register bundle identifier` | Taken by another account. Change the prefix per step 2. |
| Share extension missing from the share sheet | Extension did not install. Delete the app, rebuild. Check YogiShare actually built. |
| Shared links never appear in the app | App Group mismatch or not enabled on both targets. Compare the string in all three places from step 2. |
| Paywall shows no price | StoreKit config not attached (use the `Yogi` scheme), or on a real build the product does not exist in App Store Connect yet. |
| Archive greyed out | Destination is a simulator. Switch to Any iOS Device (arm64). |
| `Invalid Bundle. Missing Info.plist value CFBundleIconName` | The app icon asset is missing from the build. Check Assets.xcassets is in the Yogi target's Copy Bundle Resources phase. |
