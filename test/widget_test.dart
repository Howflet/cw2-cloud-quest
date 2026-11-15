import 'package:cloud_quest/services/challenge_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing progress document means no reward yet', () {
    final p = Progress.fromMap(null);
    expect(p.completed, isFalse);
    expect(p.points, 0);
    expect(p.badgeId, isNull);
  });

  test('progress document written by completeToday is parsed', () {
    final p = Progress.fromMap({
      'completed': true,
      'points': 10,
      'badgeId': 'first-quest',
    });
    expect(p.completed, isTrue);
    expect(p.points, 10);
    expect(p.badgeId, 'first-quest');
  });
}
