# Android / Play Store Setup Checklist

Complete these before distributing to testers.

> **Status (2026-07-01):** App is live on a **closed testing** track in Play Console. Testers installed via opt-in link; Google Sign-In verified working. Remaining: subscriptions setup, license testers, purchase test pass.

---

## 1. Release Signing (BLOCKER — currently signed with debug key)

`android/app/build.gradle.kts` line 38 still uses the debug key. Play Console rejects debug-signed AABs.

- [x] Generate an upload keystore (keep it OUT of git):
  ```
  keytool -genkey -v -keystore %USERPROFILE%\doro-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- [x] Create `android/key.properties` (add to `.gitignore`):
  ```
  storePassword=<password>
  keyPassword=<password>
  keyAlias=upload
  storeFile=C:/Users/hanju/doro-upload.jks
  ```
- [x] Wire it into `build.gradle.kts` release signingConfig (standard Flutter pattern)
- [x] `flutter build appbundle --release` → confirm zero errors

## 2. Play Console — App Setup

- [x] Create app in [Play Console](https://play.google.com/console) (`com.elanordigital.doro`)
- [ ] Complete: Store listing, Content rating, Data safety form, Privacy policy URL

## 3. Play Console — Subscriptions

- [ ] Monetize → Products → Subscriptions → Create:

  | Subscription ID | Base plan | Price |
  |---|---|---|
  | `doro_premium_monthly` | monthly auto-renewing | $1.99 / month |
  | `doro_premium_yearly` | yearly auto-renewing | $12.99 / year |

  IDs must match `AppConstants.iapMonthlyId` / `iapYearlyId` exactly.
  Keep ONE base plan per subscription (in_app_purchase maps product ID = subscription ID).
- [ ] Activate both subscriptions

## 4. Testing Track

- [x] Upload signed AAB to Testing → Closed testing (subscriptions don't work until
      the app exists on a track)
- [x] Add tester emails (up to 100), share the opt-in link
- [x] Testers install via the opt-in link from Play Store

## 5. License Testers (free test purchases)

- [ ] Play Console → Settings → License testing → add tester Gmail accounts
- [ ] License testers see "Test card" payment methods and are never charged
- [ ] Test renewals are accelerated: monthly = 5 min, yearly = 30 min;
      auto-cancels after 6 renewals
- [ ] Anyone NOT on the license list pays real money — add every tester here

## 6. Test Pass

- [ ] Purchase monthly + yearly with a license tester account
- [ ] Cancel via Play Store → Payments & subscriptions → Subscriptions
- [ ] Verify app revokes premium after expiry (PurchaseService revokes on Android
      when startup restore returns no active subscription)
- [ ] Restore purchases after reinstall
- [x] Google Sign-In on device + Play-Store-enabled emulator
- [ ] Sync round-trip (premium account, two devices)
