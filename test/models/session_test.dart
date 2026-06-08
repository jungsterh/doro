import 'package:flutter_test/flutter_test.dart';
import 'package:doro/models/session.dart';

void main() {
  final startTime = DateTime(2024, 1, 15, 10, 0);
  final endTime = DateTime(2024, 1, 15, 11, 0);

  Session makeSession({
    String id = 'session-1',
    String taskId = 'task-1',
    DateTime? start,
    DateTime? end,
    int durationSeconds = 3600,
    String? comment,
  }) =>
      Session(
        id: id,
        taskId: taskId,
        startTime: start ?? startTime,
        endTime: end,
        durationSeconds: durationSeconds,
        comment: comment,
      );

  // ---------------------------------------------------------------------------
  group('Session.isCompleted', () {
    test('true when endTime is set', () {
      expect(makeSession(end: endTime).isCompleted, isTrue);
    });

    test('false when endTime is null', () {
      expect(makeSession().isCompleted, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  group('Session.duration', () {
    test('returns Duration matching durationSeconds', () {
      expect(makeSession(durationSeconds: 90).duration, const Duration(seconds: 90));
    });

    test('zero seconds → Duration.zero', () {
      expect(makeSession(durationSeconds: 0).duration, Duration.zero);
    });

    test('large value (24h)', () {
      expect(
        makeSession(durationSeconds: 86400).duration,
        const Duration(hours: 24),
      );
    });
  });

  // ---------------------------------------------------------------------------
  group('Session.toMap / fromMap', () {
    test('roundtrip with endTime and comment', () {
      final s = makeSession(end: endTime, comment: 'Great session');
      final result = Session.fromMap(s.toMap());
      expect(result.id, s.id);
      expect(result.taskId, s.taskId);
      expect(result.startTime, s.startTime);
      expect(result.endTime, s.endTime);
      expect(result.durationSeconds, s.durationSeconds);
      expect(result.comment, s.comment);
    });

    test('roundtrip without endTime and comment stores nulls', () {
      final result = Session.fromMap(makeSession().toMap());
      expect(result.endTime, isNull);
      expect(result.comment, isNull);
    });

    test('toMap uses correct snake_case keys', () {
      final map = makeSession(end: endTime, comment: 'test').toMap();
      expect(map['id'], 'session-1');
      expect(map['task_id'], 'task-1');
      expect(map['start_time'], startTime.toIso8601String());
      expect(map['end_time'], endTime.toIso8601String());
      expect(map['duration_seconds'], 3600);
      expect(map['comment'], 'test');
    });

    test('toMap end_time is null when no endTime', () {
      expect(makeSession().toMap()['end_time'], isNull);
    });
  });

  // ---------------------------------------------------------------------------
  group('Session.toJson / fromJson', () {
    test('roundtrip preserves all fields', () {
      final s = makeSession(end: endTime, comment: 'noted');
      final result = Session.fromJson(s.toJson());
      expect(result.id, s.id);
      expect(result.taskId, s.taskId);
      expect(result.endTime, s.endTime);
      expect(result.comment, s.comment);
    });

    test('toJson and toMap produce identical output', () {
      final s = makeSession(end: endTime, comment: 'x');
      expect(s.toJson(), s.toMap());
    });

    test('fromJson handles null endTime and comment', () {
      final json = {
        'id': 's1',
        'task_id': 't1',
        'start_time': startTime.toIso8601String(),
        'end_time': null,
        'duration_seconds': 0,
        'comment': null,
      };
      final s = Session.fromJson(json);
      expect(s.endTime, isNull);
      expect(s.comment, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  group('Session.copyWith', () {
    test('no args returns identical values', () {
      final s = makeSession(end: endTime, comment: 'keep');
      final copy = s.copyWith();
      expect(copy.id, s.id);
      expect(copy.durationSeconds, s.durationSeconds);
      expect(copy.endTime, s.endTime);
      expect(copy.comment, s.comment);
    });

    test('updates durationSeconds', () {
      final updated = makeSession().copyWith(durationSeconds: 999);
      expect(updated.durationSeconds, 999);
      expect(updated.id, 'session-1');
    });

    test('clearEndTime=true sets endTime to null', () {
      final updated = makeSession(end: endTime).copyWith(clearEndTime: true);
      expect(updated.endTime, isNull);
    });

    test('clearEndTime=false preserves existing endTime', () {
      final updated = makeSession(end: endTime).copyWith(clearEndTime: false);
      expect(updated.endTime, endTime);
    });

    test('clearComment=true sets comment to null', () {
      final updated = makeSession(comment: 'hello').copyWith(clearComment: true);
      expect(updated.comment, isNull);
    });

    test('clearComment=false preserves existing comment', () {
      final updated = makeSession(comment: 'keep').copyWith(clearComment: false);
      expect(updated.comment, 'keep');
    });

    test('can set new endTime via copyWith', () {
      final newEnd = DateTime(2025, 1, 1);
      final updated = makeSession().copyWith(endTime: newEnd);
      expect(updated.endTime, newEnd);
    });
  });

  // ---------------------------------------------------------------------------
  group('Session equality and hashCode', () {
    test('same id → equal regardless of other fields', () {
      expect(makeSession(), equals(makeSession(durationSeconds: 9999)));
    });

    test('different id → not equal', () {
      expect(makeSession(id: 'a'), isNot(equals(makeSession(id: 'b'))));
    });

    test('hashCode is consistent for same id', () {
      expect(makeSession().hashCode, makeSession().hashCode);
    });
  });

  // ---------------------------------------------------------------------------
  test('toString contains id and taskId', () {
    final s = makeSession().toString();
    expect(s, contains('session-1'));
    expect(s, contains('task-1'));
  });
}
