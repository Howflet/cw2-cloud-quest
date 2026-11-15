import 'package:cloud_functions/cloud_functions.dart';

class RewardResult {
  const RewardResult({
    required this.points,
    required this.badgeId,
    required this.alreadyCompleted,
  });
  final int points;
  final String badgeId;
  final bool alreadyCompleted;
}

/// Asks the trusted Function to complete today's challenge. The client sends
/// only the challenge id. UID, points and badge are decided on the server.
Future<RewardResult> completeChallenge() async {
  final callable = FirebaseFunctions.instance.httpsCallable('completeToday');
  final result = await callable.call<Map<String, dynamic>>({
    'challengeId': 'today',
  });
  final data = Map<String, dynamic>.from(result.data);
  return RewardResult(
    points: (data['points'] as num).toInt(),
    badgeId: data['badgeId'] as String,
    alreadyCompleted: data['alreadyCompleted'] == true,
  );
}
