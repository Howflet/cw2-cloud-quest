import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Challenge {
  const Challenge({required this.title, required this.prompt});
  final String title;
  final String prompt;
}

class Progress {
  const Progress({
    required this.completed,
    required this.points,
    required this.badgeId,
  });
  const Progress.empty() : completed = false, points = 0, badgeId = null;

  final bool completed;
  final int points;
  final String? badgeId;

  factory Progress.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const Progress.empty();
    return Progress(
      completed: data['completed'] == true,
      points: (data['points'] as num?)?.toInt() ?? 0,
      badgeId: data['badgeId'] as String?,
    );
  }
}

final FirebaseFirestore _db = FirebaseFirestore.instance;

/// Reads the shared, read-only challenge. Requires sign-in (rules enforce it).
Future<Challenge> loadChallenge() async {
  if (FirebaseAuth.instance.currentUser == null) {
    throw StateError('Sign in before loading the challenge.');
  }
  final snap = await _db.collection('challenges').doc('today').get();
  final data = snap.data();
  if (data == null) {
    throw StateError('Today\'s challenge has not been published yet.');
  }
  return Challenge(
    title: data['title'] as String? ?? 'Today\'s challenge',
    prompt: data['prompt'] as String? ?? '',
  );
}

/// Live view of ONLY the signed-in learner's progress document. The client
/// never writes it; the completeToday Function does.
Stream<Progress> watchMyProgress(String uid) => _db
    .collection('users')
    .doc(uid)
    .collection('progress')
    .doc('today')
    .snapshots()
    .map((snap) => Progress.fromMap(snap.data()));
