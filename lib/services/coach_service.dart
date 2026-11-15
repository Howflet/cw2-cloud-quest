import 'package:cloud_functions/cloud_functions.dart';

const int maxQuestionLength = 300;

/// Calls the authenticated, server-side Quest Coach. Only the question text is
/// sent: no UID, points, or tool names. The server validates it again.
Future<String> getQuestHint(String question) async {
  final trimmed = question.trim();
  final safeQuestion = trimmed.length > maxQuestionLength
      ? trimmed.substring(0, maxQuestionLength)
      : trimmed;
  final callable = FirebaseFunctions.instance.httpsCallable('askQuestCoach');
  final result = await callable.call<Map<String, dynamic>>({
    'question': safeQuestion,
  });
  return result.data['reply'] as String;
}
