# iOS Setup Checklist

Complete these on your Mac before submitting to the App Store.

---

## Firebase & Google Sign-In

- [ ] Place `GoogleService-Info.plist` inside `ios/Runner/` in Xcode
  - Open `ios/Runner.xcworkspace` in Xcode
  - Right-click `Runner` folder → Add Files to "Runner"
  - Select `GoogleService-Info.plist`, check **"Copy items if needed"** and **"Add to targets: Runner"**
- [ ] Verify `CLIENT_ID` is present in `GoogleService-Info.plist` (needed by `google_sign_in`)
- [ ] Add the reversed client ID as a URL scheme in Xcode
  - `Runner` target → Info → URL Types → `+`
  - URL Schemes: paste the value of `REVERSED_CLIENT_ID` from `GoogleService-Info.plist`
  - Identifier: `com.google.reverseClientId`

---

## App Store Connect — Subscriptions

- [ ] Log in to [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Go to your app → **Monetization → Subscriptions**
- [ ] Create a **Subscription Group** (e.g. "Doro Premium")
- [ ] Create two subscriptions inside the group:

  | Reference Name | Product ID | Price |
  |----------------|------------|-------|
  | Doro Monthly | `doro_premium_monthly` | $1.99 / month |
  | Doro Yearly | `doro_premium_yearly` | $11.99 / year |

- [ ] Set availability, localizations (display name + description), and review screenshot for each
- [ ] Submit subscriptions for review (can be done alongside the first app review)

---

## Sign In with Apple (required by Apple if offering Google Sign-In)

- [ ] Enable **Sign In with Apple** capability in Xcode
  - `Runner` target → Signing & Capabilities → `+` Capability → Sign In with Apple
- [ ] Confirm `sign_in_with_apple` Flutter package is in `pubspec.yaml` ✓ (already added)
- [ ] Enable Sign In with Apple in App Store Connect → App → Capabilities

---

## Supabase — Apple OAuth

- [ ] In Supabase Dashboard → Auth → Providers → Apple
  - Add your Apple **Services ID** (create one in Apple Developer → Certificates, IDs & Profiles → Identifiers → Services IDs)
  - Add your **Team ID**, **Key ID**, and **private key** (.p8 file from Apple Developer)
  - Callback URL to whitelist: `https://xwgkgvlzrvmybjhshfzc.supabase.co/auth/v1/callback`

---

## Build & Test

- [ ] Run `flutter pub get` after pulling latest changes (firebase_core was added)
- [ ] Run `flutter build ios` and confirm zero errors
- [ ] Test Google Sign-In on a physical device (simulator does not support Google Sign-In)
- [ ] Test Sign In with Apple on a physical device (requires a real Apple ID)
- [ ] Test subscription purchase in sandbox (use a Sandbox Tester account from App Store Connect)
- [ ] Test restore purchases after reinstall
