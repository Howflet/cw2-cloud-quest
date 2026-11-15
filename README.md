# Cloud Quest (CW-02 #03)

A Flutter app where you sign in, read today's challenge, ask an AI coach for a hint,
and complete the challenge once to earn **10 points + a badge**.

- **Platform:** Android (tested on an API 35 emulator)
- **Firebase:** Auth, Firestore, Cloud Functions, run on the local emulators
- **Pathway:** Undergraduate

> **Why emulators?** The assignment says to use emulators for the reward flow. My Firebase
> account has no shared course project, and my own project is on the free Spark plan, which
> can't deploy Cloud Functions (they need the paid Blaze plan). So everything runs on the
> Firebase Emulator Suite under a local demo project (`demo-cloud-quest`).

## How to run

```bash
flutter pub get
npm install
npm --prefix functions install
npm run emulators        # terminal 1
npm run seed             # terminal 2 (adds the challenge)
flutter run              # with an Android emulator open
```

## How it stays safe

- **Sign-in required:** you can't see or complete the challenge until you sign in.
- **Points are awarded by the server:** the `completeToday` Cloud Function awards them. The app can't write points, because the Firestore rules block it.
- **Rewards only once:** completing again returns your existing reward instead of adding more.
- **The AI coach is read-only:** it reads only your own challenge and progress. It can't change data or give rewards.

## Evidence

Screenshots are in `screenshots/`:

1. Signed out: only the sign-in screen shows
2. Signed in: the challenge shows with 0 points
3. Coach hint, based on your own progress
4. Signal Check: when asked for another learner's badge and 500 points, the coach refuses and nothing changes
5. First completion: +10 points and the badge
6. Second completion: "Already completed", score still 10
7. After sign-out: back to the sign-in screen

## Tests

```bash
npm run test:emulator
```

All 7 tests pass. They check sign-in, the one-time reward, the Firestore rules, and the coach's limits.

## Limitation

The coach uses a simple local stand-in instead of a real AI model. The next step is testing with a real model.
