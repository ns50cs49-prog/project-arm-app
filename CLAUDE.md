# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Flutter clinic queue/booking app ("Arm care Physical Therapy") with three distinct roles — patient, doctor, admin — each reached via a different, non-obvious auth path (see below). All UI text is Thai.

## Commands

```
flutter pub get                          # install dependencies
flutter analyze                          # static analysis (whole project)
flutter analyze lib/some_file.dart       # analyze a single file
flutter test                             # run all unit/widget tests
flutter test test/admin_home_test.dart   # run a single test file
flutter run -d <device-id>               # run on a device (flutter devices to list)
```

`test/widget_test.dart`'s "confirm booking opens appointment page" test fails on a clean checkout — this is pre-existing/unrelated to feature work, not a regression signal to chase.

There is also `integration_test/booking_flow_test.dart` (+ `test_driver/integration_test.dart`) exercising the real Firestore-emulator write/read/transaction path end-to-end. Running it via `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/booking_flow_test.dart -d chrome` needs `chromedriver` on PATH and port 4444 free; getting DWDS to attach through chromedriver has been unreliable in this environment — treat it as a starting point, not a working CI path.

## Architecture

### Three roles, three different login mechanisms (`login.dart` / `main.dart`)

- **Patient**: real Firebase Auth (`signInWithEmailAndPassword`) → `AuthGate` in `main.dart` routes to `PatientHomePage` (`patient_home.dart`).
- **Admin**: also real Firebase Auth, but gated by a **hardcoded email string** (`raddawan3079@gmail.com`) duplicated in both `login.dart` (`_adminEmail`) and `main.dart`'s `AuthGate` — if this identity ever changes, update both. Routes to `AdminHomePage` (`admin_home.dart`).
- **Doctor**: **not Firebase-authenticated at all**. `login.dart` checks `DoctorRepository.findByEmailAndLoginId(email, loginId)` against an in-memory mock list *before* attempting real Firebase Auth; on match it navigates straight to `DoctorPage` (`doctor_page.dart`), bypassing `AuthGate` entirely. Any Firestore write triggered by doctor-side code therefore runs unauthenticated — the deployed Firestore rules must allow that, or doctor actions will fail with `permission-denied`.

### `doctor_page.dart` vs `admin_home.dart`

Previously named `docter.dart`/`docter_home.dart` (near-identical names for unrelated pages) — renamed for clarity:
- `doctor_page.dart` → `DoctorPage`: the **doctor's own** app (add availability + live queue + "เรียกคิว" call-next, history, profile).
- `admin_home.dart` → `AdminHomePage`: the **admin** app (manage doctor accounts, manage patients/treatment history via `PatientHistoryPage` + `PatientTreatmentDetailPage`).
- `history.dart` → `HistoryPage`: a real-time treatment-history list backed by `DoctorRepository.watchTreatmentsForPatientUserId`/`watchAllTreatments`. Used both as the patient's own "ประวัติ" tab (`patient_home.dart`, scoped to their uid) and as the admin's overview tab (`admin_home.dart`, unscoped — shows every patient's history).

### `DoctorRepository` (`doctor_repository.dart`) — mixed persistence, by design

This static class is the single data-access layer, but its collections have different backing stores:
- `doctors` (accounts) — an **in-memory static list**, reset on every app restart. Not Firestore.
- Availability (`doctorAvailability` collection), bookings (`appointments` collection), and treatment history (`treatmentHistory` collection) — **real Firestore**, since the doctor, patient, and admin apps all need to see the same live/persisted data.
  - `addTreatmentRecord` is called from `doctor_page.dart` when the doctor presses "เสร็จสิ้น" — it's written *before* `markAppointmentCompleted`, so a completed appointment can never end up missing its history entry. Records store `patientUserId` (when the booking has one) so a patient's own history (`history.dart`'s `HistoryPage`) can query by uid rather than by display name; the admin patient-management screens (`admin_home.dart`) query by `patientName` instead, since that's all they have to search on.
  - `bookAvailabilitySlot` uses a Firestore transaction to atomically check `bookedCount < maxQueue` and assign a sequential zero-padded queue number — this is the only place overbooking is actually prevented.
  - `watchAvailabilitiesForDoctor` / `watchAppointmentsForDoctor` filter results client-side to **today's date** (`_todayKey()`) so slots/queues from other days don't linger in the UI. Old docs aren't deleted, just filtered out — don't "fix" this by adding a Firestore `where` on date without checking why it was done client-side (avoids composite-index requirements for the existing equality filters).
  - Writes are wrapped in `_withRetry` (retries `unavailable`/`deadline-exceeded` a couple of times) because the Android Firestore SDK's gRPC channel has been observed to drop with "Channel shutdownNow invoked" on some devices/networks.

### Local Firestore emulator wiring (dev-only, `main.dart`)

In `kDebugMode`, `main.dart` points Firestore at a **local emulator** via a hardcoded LAN IP (currently `10.10.0.169:8080`), not `localhost` — connecting via `localhost`/adb-reverse over USB triggered the same gRPC channel-drop issue on the test Android device; a direct LAN IP (phone and dev machine on the same WiFi) was the workaround that held up. If this IP changes (different machine, different network), update it here or the doctor/patient flows will silently time out.

Related pieces this depends on:
- `firebase.json` configures the emulator (`firestore` + `ui`, both bound to `0.0.0.0`) and points `firestore.rules` at `firestore.rules`, which is a **wide-open dev ruleset** (`allow read, write: if true;`) — fine for the local emulator, not what should ever be deployed to the real project.
- `android/app/src/main/res/xml/network_security_config.xml` (referenced from `AndroidManifest.xml`) allows cleartext traffic to `localhost`/`127.0.0.1`/`10.0.2.2`/the LAN IP — required because Android blocks plaintext gRPC by default on API 28+.
- The dev machine's Windows network profile must be **Private**, not Public — on a Public profile, Windows Firewall silently drops inbound connections from other devices (like the test phone) to the emulator port, which looks identical to a code bug (indefinite hang / timeout) from the Flutter side.
- Run the emulator with `firebase emulators:start --only firestore` before testing against it.
