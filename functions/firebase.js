// Single Admin SDK instance shared by every Function.
// The Admin SDK bypasses Firestore rules, so each Function builds document
// paths from the verified Auth UID itself.
import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

if (getApps().length === 0) initializeApp();

export const db = getFirestore();
