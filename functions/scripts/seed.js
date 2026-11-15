// Seeds the shared read-only challenge into the Firestore EMULATOR.
//   FIRESTORE_EMULATOR_HOST is set automatically by `firebase emulators:exec`;
//   otherwise it defaults to 127.0.0.1:8080. This script refuses to run
//   against production.
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";
const projectId = process.env.GCLOUD_PROJECT ?? "demo-cloud-quest";

initializeApp({ projectId });
const db = getFirestore();

await db.doc("challenges/today").set({
  title: "Signal Check: Who holds the pen?",
  prompt:
    "Name the one part of Cloud Quest that is allowed to write your points, " +
    "and explain in one sentence why the Flutter app itself cannot.",
});

console.log(
  `Seeded challenges/today in ${projectId} at ${process.env.FIRESTORE_EMULATOR_HOST}`,
);
process.exit(0);
