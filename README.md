# Cloud Quest: Signal Check (CW-02 #03, Firebase, Version 2)

A Flutter app where a learner signs in, reads today's challenge from Cloud Firestore,
asks a supervised **AI Quest Coach** for a hint, and completes the challenge **once** to
earn **10 points + the "First Quest" badge**. A trusted callable Cloud Function awards
the reward. The coach can only *read* the caller's own quest state and cannot write
data or award rewards.

- **Pathway:** Undergraduate (it also includes the graduate automated emulator test)
- **Platform target:** Android (tested on an Android 15 / API 35 emulator, `sdk gphone64 arm64`).
  iOS code is included but was not built, because Xcode isn't installed on the dev machine.
- **Firebase:** Auth, Cloud Firestore, Cloud Functions (2nd gen callables), and Genkit,
  all run on the **Firebase Emulator Suite** under the demo project `demo-cloud-quest`.
- **Push notifications:** not implemented (optional extension).

---

## Project layout

```
cw2/
├── lib/
│   ├── main.dart                     # Firebase init + emulator wiring
│   ├── app.dart                      # Auth gate (StreamBuilder on authStateChanges)
│   ├── firebase_options.dart         # demo-project options (replace with flutterfire configure)
│   ├── screens/sign_in_screen.dart   # register / sign in, friendly errors
│   ├── screens/challenge_screen.dart # challenge, progress, Complete, Quest Coach
│   └── services/                     # auth, challenge (Firestore), reward + coach (callables)
├── functions/
│   ├── index.js                      # completeToday + askQuestCoach callables
│   ├── questCoach.js                 # Genkit flow, readMyQuestState tool, emulator mock model
│   ├── firebase.js                   # shared Admin SDK instance
│   ├── scripts/seed.js               # seeds challenges/today into the emulator
│   └── test/boundary.test.js         # automated emulator boundary tests
├── firestore.rules                   # read own progress only; no client writes
├── firebase.json / .firebaserc       # emulator ports + demo project
├── screenshots/                      # device evidence + test output
└── REFLECTION.md                     # 100–150 word reflection (draft)
```

## Setup and run

Prerequisites: Flutter 3.x, Node 22, Java 21+ (for the Firestore emulator), and an Android emulator.

```bash
# 1. Dependencies
flutter pub get
npm install                 # local Firebase CLI (npx firebase …)
npm --prefix functions install

# 2. Terminal A: start the emulators (Auth 9099, Firestore 8080, Functions 5001, UI 4000)
npm run emulators

# 3. Terminal B: seed the shared challenge
npm run seed

# 4. Start an Android emulator and run the app
flutter emulators --launch Test_API_35
flutter devices
flutter run                 # debug; or: flutter run --profile (faster on slow emulators)
```

The app connects to the emulators at `10.0.2.2` on Android and `localhost` on iOS.
For a physical phone, pass your computer's LAN IP:
`flutter run --dart-define=EMULATOR_HOST=192.168.x.x`.

**Using the course Firebase project instead of the demo project:**
`flutterfire configure --project=<course-project-id> --platforms=android,ios`,
then `flutter run --dart-define=USE_EMULATORS=false`, and deploy only the backend:
`npx firebase use <alias> && npx firebase deploy --only functions,firestore:rules`.
For a real model, set `GEMINI_API_KEY` as a Functions secret. Without it, the coach uses
the built-in deterministic emulator mock, so no personal key or paid model call is needed.

## Data model

| Document | Fields | Writer | Purpose |
|---|---|---|---|
| `challenges/today` | `title`, `prompt` | seed script (Admin SDK) | Shared, read-only challenge |
| `users/{uid}/progress/today` | `completed`, `points`, `badgeId`, `completedAt` | `completeToday` Function only | Private, idempotent reward |

Reward values (`10`, `"first-quest"`) are constants in `functions/index.js`, not client data.

## Trust boundaries

```
Flutter app ──sign in──► Firebase Auth (verified ID token)
     │ read challenge + own progress ──► Firestore (rules: auth required; own uid only; no writes)
     │ "Get hint" {question} ──► askQuestCoach callable
     │                               └─► Genkit flow ─► readMyQuestState (read-only, uid from Auth)
     │                                               └─► model (mock / Gemini) ─► plain-text hint
     └ "Complete" {challengeId} ──► completeToday callable ─► transaction ─► progress (once)
```

- **Auth vs authorization.** Auth says *who* the learner is. Firestore rules decide what the
  client may read (the challenge, and only their own progress) and deny all client writes.
- **Reward.** `completeToday` takes the UID from `request.auth`, ignores any client-sent
  points/uid/badge, and runs a transaction: if progress already exists it returns
  `alreadyCompleted: true` with the same values. The Admin SDK bypasses rules, so the
  Function builds the path from the verified UID itself.
- **Quest Coach (AI tool).** `askQuestCoach` requires auth and a non-blank question of 300
  characters or fewer. The flow **always calls `readMyQuestState` first**. That tool takes *no
  input*, reads the UID from the verified Auth context, and reads exactly `challenges/today`
  and `users/{thatUid}/progress/today`. It is the only allowlisted tool and is read-only. The
  agent has no write path and cannot call `completeToday`. Learner text is wrapped as
  untrusted data. If the tool fails, the callable returns `unavailable` instead of an
  invented hint. Replies are plain text and checked for false "reward granted" claims.
  These are code-level limits; the system prompt is guidance only.
- **Learner control.** Only the learner's explicit **Complete** button requests a reward.

## Evidence (Android emulator, API 35)

| Check | Result | Evidence |
|---|---|---|
| App launches; signed-out state gates everything | Sign-in screen only | `screenshots/01_signed_out.png` |
| Register / sign in | Challenge + 0 points shown for `learner1@example.test` | `screenshots/02_signed_in.png` |
| Grounded coach hint | Names the learner's challenge title and 0-point state, gives a hint, not the answer | `screenshots/03_coach_hint.png` |
| **Signal Check** (adversarial request) | "I can only read your own quest, so I can't share another learner's data, and I can't change points or badges." Progress stayed at 0 points, with no badge | `screenshots/04_signal_check.png` |
| Complete once | "+10 points and the first-quest badge" | `screenshots/05_complete_once.png` |
| Retry completion | "Already completed. Your 10 points and badge are unchanged." Score still 10 | `screenshots/06_retry_no_duplicate.png` |
| Firestore record after retry | `completed: true, points: 10, badgeId: "first-quest"` (one record) | `screenshots/progress_record.txt` |
| Sign out | Returns to sign-in; progress and coach are no longer visible | `screenshots/07_signed_out_after_logout.png` |
| Direct client reward write | Denied by rules (HTTP 403) | automated test 3 |

### Automated emulator test

```bash
npm run test:emulator
```

This starts Auth, Firestore, and Functions emulators, seeds the challenge, runs
`functions/test/boundary.test.js`, and shuts down. Result:

```
ok 1 - completeToday rejects signed-out callers
ok 2 - completeToday awards 10 points + badge once; retry does not duplicate
ok 3 - rules deny direct client reward writes and cross-user reads
ok 4 - askQuestCoach requires auth and a non-blank question of at most 300 chars
ok 5 - coach grounds its hint in the caller's own state and ignores a client-supplied uid
ok 6 - Signal Check: adversarial request discloses nothing and changes nothing
ok 7 - coach returns an error, not an invented hint, when its tool or model fails
# tests 7  # pass 7  # fail 0
```

Dart unit tests (`flutter test`) check how progress documents are parsed.

## Limitations / next steps

- The coach's hint text comes from a deterministic emulator mock. With a live model,
  the same code-level boundaries apply, but hint quality would need its own evaluation.
- The reward-claim filter is a simple pattern check. A stricter version would generate a
  structured output (a hint field only) instead of free text.
- Only one fixed challenge (`today`). There's no daily rotation or streaks, by design.
- iOS was not built or tested on this machine.
