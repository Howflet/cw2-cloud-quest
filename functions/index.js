// Trusted backend for Cloud Quest.
//
// completeToday  - callable that awards the fixed reward (10 points + "first-quest")
//                  exactly once per learner, inside a Firestore transaction.
// askQuestCoach  - callable that runs the supervised, read-only Quest Coach agent
//                  (see questCoach.js).
//
// Both derive the learner's UID from the verified callable Auth context. Neither
// accepts a UID, score, badge, or tool name from the client.

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "./firebase.js";
import { runQuestCoach } from "./questCoach.js";

// Reward values live only here, never in client-editable data.
export const REWARD_POINTS = 10;
export const REWARD_BADGE = "first-quest";
const KNOWN_CHALLENGE = "today";
const MAX_QUESTION_LENGTH = 300;

export const completeToday = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  if (request.data?.challengeId !== KNOWN_CHALLENGE) {
    throw new HttpsError("invalid-argument", "Unknown challenge.");
  }

  const uid = request.auth.uid; // verified by the Functions runtime
  const challengeRef = db.doc(`challenges/${KNOWN_CHALLENGE}`);
  const progressRef = db.doc(`users/${uid}/progress/${KNOWN_CHALLENGE}`);

  return db.runTransaction(async (transaction) => {
    const [challenge, progress] = await Promise.all([
      transaction.get(challengeRef),
      transaction.get(progressRef),
    ]);
    if (!challenge.exists) {
      throw new HttpsError("failed-precondition", "Today's challenge is not available.");
    }

    // Idempotent: a retry returns the existing reward instead of adding points.
    if (progress.exists && progress.data().completed === true) {
      return {
        completed: true,
        points: progress.data().points,
        badgeId: progress.data().badgeId,
        alreadyCompleted: true,
      };
    }

    const reward = {
      completed: true,
      points: REWARD_POINTS,
      badgeId: REWARD_BADGE,
      completedAt: FieldValue.serverTimestamp(),
    };
    transaction.set(progressRef, reward);
    return {
      completed: true,
      points: reward.points,
      badgeId: reward.badgeId,
      alreadyCompleted: false,
    };
  });
});

export const askQuestCoach = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in to talk to the Quest Coach.");
  }
  const question = request.data?.question;
  if (typeof question !== "string" || question.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Ask a non-blank question.");
  }
  if (question.trim().length > MAX_QUESTION_LENGTH) {
    throw new HttpsError(
      "invalid-argument",
      `Questions are limited to ${MAX_QUESTION_LENGTH} characters.`,
    );
  }

  // Failure simulation exists only in the local emulator so the
  // "tool failure does not produce an invented hint" check is repeatable.
  const simulate =
    process.env.FUNCTIONS_EMULATOR === "true" ? request.data?.simulate : undefined;

  // Only the verified UID is passed on. Any uid/points/tool fields sent by the
  // client are ignored.
  return runQuestCoach({
    uid: request.auth.uid,
    question: question.trim(),
    simulate,
  });
});
