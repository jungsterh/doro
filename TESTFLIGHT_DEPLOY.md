# Deploy Doro to TestFlight

Step-by-step for your **Mac**. Assumes Apple Developer Program is active and the app record already exists in App Store Connect.

- **Bundle ID:** `com.elanordigital.doro`
- **Current version:** `1.0.0+2` (marketing `1.0.0`, build `2`)
- **Method:** Archive in Xcode → upload via Organizer

> **Status (2026-07-01):** ✅ First deploy done — build uploaded, processed, installed on device via TestFlight, and added to a closed testing group. Google Sign-In confirmed working in the TestFlight build. This doc is now the repeat loop — see "Next time (the short loop)" below.

> One-time prerequisites (Firebase plist, Sign In with Apple capability, Apple OAuth in Supabase, subscriptions) live in `IOS_CHECKLIST.md`. Do those first if you haven't — a build missing them will install but Google/Apple sign-in and IAP will fail. The steps below are the build-and-ship loop.

---

## 0. Confirm the App Store Connect record matches

In [App Store Connect](https://appstoreconnect.apple.com) → My Apps → Doro, verify the bundle ID is exactly `com.elanordigital.doro`. If the record was created with a different ID, either fix it here or update `PRODUCT_BUNDLE_IDENTIFIER` in Xcode — they must match or the upload is rejected.

---

## 1. Pull latest & sanity build

```bash
cd <doro-repo>
flutter --version            # confirm Flutter installed on this Mac
flutter pub get
cd ios && pod install && cd ..
flutter analyze              # zero-warning policy
flutter test
flutter build ios --release  # confirm a clean release build before archiving
```

If `pod install` complains, run `cd ios && pod repo update && pod install`.

---

## 2. Bump the build number

TestFlight rejects a build number it has already seen. Every upload needs a higher `+N`. In `pubspec.yaml`:

```yaml
version: 1.0.0+3   # bump the number after the +
```

Keep `1.0.0` as the marketing version for now; just increment the build each upload. Then re-run `flutter pub get`.

---

## 3. Open the workspace in Xcode

```bash
open ios/Runner.xcworkspace
```

Open the **.xcworkspace**, not the .xcodeproj (CocoaPods won't link otherwise).

---

## 4. Configure signing (one-time, then it sticks)

1. Select the **Runner** project → **Runner** target → **Signing & Capabilities**.
2. Check **Automatically manage signing**.
3. Set **Team** to your Apple Developer team (the team field is currently empty in the project).
4. Confirm **Bundle Identifier** = `com.elanordigital.doro`.
5. Xcode will create/download the provisioning profile. Resolve any red errors here before continuing.
6. While you're here, confirm the **Sign In with Apple** capability is present (required because the app offers Google Sign-In).

---

## 5. Select the archive destination

In the scheme/device selector at the top, choose **Any iOS Device (arm64)**. You cannot archive while a simulator is selected.

---

## 6. Archive

Menu: **Product → Archive**.

This builds a release archive (a few minutes). When it finishes, the **Organizer** window opens with your archive listed. If Archive is greyed out, you still have a simulator selected (go back to step 5).

---

## 7. Upload to App Store Connect

In the Organizer:

1. Select the new archive → **Distribute App**.
2. Choose **App Store Connect** → **Upload**.
3. Accept the defaults (automatic signing, include symbols, manage version). Strip bitcode prompt: leave defaults.
4. Let it validate and upload. On success you'll see "Upload Successful".

---

## 8. Wait for processing & export compliance

1. Back in App Store Connect → Doro → **TestFlight** tab. The build shows **"Processing"** for 5–30 min.
2. When ready it may flag **"Missing Compliance"**. Click it and answer the encryption question.
   - Doro uses only standard HTTPS/TLS → typically **"No"** to proprietary encryption (i.e. exempt). Set this once and it carries forward.
   - To avoid the prompt entirely later, add to `ios/Runner/Info.plist`:
     ```xml
     <key>ITSAppUsesNonExemptEncryption</key>
     <false/>
     ```

---

## 9. Add testers

**Internal testing** (fastest, up to 100 users on your team, no review):

1. TestFlight → **Internal Testing** → create/select a group.
2. Add testers by their App Store Connect email. They install the **TestFlight** app and accept.
3. Assign the processed build to the group → available within minutes.

**External testing** (up to 10,000 via public link, requires a quick Beta App Review):

1. TestFlight → **External Testing** → create a group, add the build.
2. Fill **Test Information** (what to test, contact email, feedback email).
3. Submit for Beta App Review (usually < 24h). Then share the public invite link.

For first round, use **Internal** — instant and no review.

---

## Next time (the short loop)

```bash
# 1. bump version in pubspec.yaml (e.g. 1.0.0+4)
flutter pub get
open ios/Runner.xcworkspace
# 2. Any iOS Device → Product → Archive → Distribute → Upload
# 3. assign build to your TestFlight group
```

---

## Common snags

- **"No account / no team"** in signing → add your Apple ID in Xcode → Settings → Accounts.
- **Archive greyed out** → simulator still selected; pick *Any iOS Device*.
- **"Invalid bundle / already used build number"** → bump `+N` in pubspec, re-run `flutter pub get`, re-archive.
- **Upload rejected for missing `GoogleService-Info.plist`** → confirm it's added to the Runner target in Xcode (see `IOS_CHECKLIST.md`).
- **Google sign-in works in dev but not TestFlight** → confirm the `REVERSED_CLIENT_ID` URL scheme is in Info.plist (it currently is: `com.googleusercontent.apps.895140321046-...`).
- **CocoaPods errors after a Flutter upgrade** → `cd ios && pod deintegrate && pod install`.
