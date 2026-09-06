# Deploying Albo from Xcode

Requires macOS with Xcode 15.4+ and an Apple Developer account ($99/yr) for anything
beyond the simulator.

For credentials and backend setup, see `CONNECT.md`. You can do everything through step 5
here with no credentials at all — the app runs on local heuristics and sample data.

---

## 1. Generate the project

There is no `.xcodeproj` in the repo; it is generated from `project.yml` so the two targets
and their capabilities stay in sync.

```bash
brew install xcodegen
cd ios/Albo
xcodegen generate
open Albo.xcodeproj
```

On first open Xcode resolves the Supabase package from GitHub. Wait for the progress bar in
the toolbar to finish before building, or the first build fails on a missing module.

**Re-run `xcodegen generate` after any pull that touches `project.yml`.** It rewrites the
project, which is why signing lives in an xcconfig rather than in Xcode's UI (step 2).

## 2. Signing — both targets

Get your Team ID from developer.apple.com → Membership. Then:

```bash
cat > Albo/Resources/Albo.local.xcconfig <<'EOF'
DEVELOPMENT_TEAM = YOUR10CHARID
EOF
```

That file is git-ignored and survives regeneration. Both targets pick it up.

If `com.sourcedai.albo` is already taken on your account, change the prefix in three places
and regenerate:

- `project.yml` → `PRODUCT_BUNDLE_IDENTIFIER` on **both** targets
- `project.yml` → the two `com.apple.security.application-groups` blocks
- `Albo/Shared/ShareInbox.swift` → `AlboAppGroup.identifier`

The app group string must match in all three or the extension writes somewhere the app
cannot read.

Then in Xcode, check both targets under Signing & Capabilities (select the project in the
navigator, then each target in the sidebar):

- **Albo** — Sign in with Apple, App Groups (`group.com.sourcedai.albo`)
- **AlboShare** — App Groups, the same identifier

Automatic signing registers these for you if your account has permission. If the App Group
row shows a red error, create it manually in the portal under Identifiers → App Groups and
click the refresh arrow in Xcode.

## 3. Run in the simulator

Pick any iPhone running iOS 17+ and press ⌘R.

The `Albo` scheme already has `Albo.storekit` attached, so the paywall shows the £29.99/yr
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
→ **Add to Albo**. If it is not there, tap "Edit Actions…" and enable it.

To debug it with breakpoints: Product → Scheme → AlboShare, press ⌘R, and pick Safari when
Xcode asks for a host app.

Two things that confuse everyone:

- The save appears in Albo when you next **open Albo**, not the instant you share. The
  extension only queues; the app does the import. That is deliberate — see the README.
- After changing extension code, delete the app from the device before reinstalling. iOS
  caches extension registrations aggressively.

## 6. Add the backend (optional until TestFlight)

Append your Supabase values to the same local xcconfig:

```
SUPABASE_URL = https:/$()/YOUR-REF.supabase.co
SUPABASE_ANON_KEY = sb_publishable_...
```

The `$()` is required — xcconfig reads a bare `//` as a comment. Full backend setup is in
`CONNECT.md`.

## 7. Archive and upload to TestFlight

First create the app record in App Store Connect with bundle ID `com.sourcedai.albo`
(My Apps → + → New App). The upload is rejected without it.

Then:

1. Bump the build number in `project.yml` (`CURRENT_PROJECT_VERSION`) and regenerate. Every
   upload needs a build number higher than the last for that version string.
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
`com.sourcedai.albo.pro.yearly` is approved alongside the build.

---

## When it fails

| Symptom | Cause |
|---|---|
| `No such module 'Supabase'` | Package still resolving, or resolution failed. File → Packages → Resolve Package Versions. |
| Signing settings vanished | You edited them in Xcode's UI and re-ran `xcodegen generate`. Put them in `Albo.local.xcconfig` instead. |
| `Failed to register bundle identifier` | Taken by another account. Change the prefix per step 2. |
| Share extension missing from the share sheet | Extension did not install. Delete the app, rebuild. Check AlboShare actually built. |
| Shared links never appear in the app | App Group mismatch or not enabled on both targets. Compare the string in all three places from step 2. |
| Paywall shows no price | StoreKit config not attached (use the `Albo` scheme), or on a real build the product does not exist in App Store Connect yet. |
| Archive greyed out | Destination is a simulator. Switch to Any iOS Device (arm64). |
| `Invalid Bundle. Missing Info.plist value CFBundleIconName` | Regenerate — the asset catalog appicon settings come from `project.yml`. |
