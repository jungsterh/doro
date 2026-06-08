import 'package:flutter_test/flutter_test.dart';
import 'package:doro/models/session.dart';
import 'package:doro/models/task.dart';

// Unit tests for model serialization used by DatabaseService
// Note: Full integration tests for DatabaseService require sqflite_common_ffi
// which needs native setup. These tests cover the serialization layer.
void main() {
  group('Task serialization', () {
    final task = Task(
      id: 'task-001',
      name: 'Deep Work',
      colorHex: '#6C63FF',
      createdAt: DateTime(2025, 3, 26, 10, 0, 0),
    );

    group('toMap() / fromMap()', () {
      test('round-trips correctly', () {
        final map = task.toMap();
        final restored = Task.fromMap(map);

        expect(restored.id, equals(task.id));
        expect(restored.name, equals(task.name));
        expect(restored.colorHex, equals(task.colorHex));
        expect(
          restored.createdAt.toIso8601String(),
          equals(task.createdAt.toIso8601String()),
        );
      });

      test('toMap() includes all required fields', () {
        final map = task.toMap();

        expect(map.containsKey('id'), isTrue);
        expect(map.containsKey('name'), isTrue);
        expect(map.containsKey('color_hex'), isTrue);
        expect(map.containsKey('created_at'), isTrue);
      });

      test('fromMap() handles string dates', () {
        final map = {
          'id': 'abc',
          'name': 'Test',
          'color_hex': '#FF0000',
          'created_at': '2025-01-15T08:30:00.000',
        };

        final restored = Task.fromMap(map);
        expect(restored.createdAt.year, equals(2025));
        expect(restored.createdAt.month, equals(1));
        expect(restored.createdAt.day, equals(15));
      });
    });

    group('toJson() / fromJson()', () {
      test('round-trips correctly for Supabase', () {
        final json = task.toJson();
        final restored = Task.fromJson(json);

        expect(restored.id, equals(task.id));
        expect(restored.name, equals(task.name));
        expect(restored.colorHex, equals(task.colorHex));
      });
    });

    group('color getter', () {
      test('parses hex color correctly', () {
        final color = task.color;
        expect(color.r, closeTo(108 / 255, 0.01));
        expect(color.g, closeTo(99 / 255, 0.01));
        expect(color.b, closeTo(255 / 255, 0.01));
      });
    });

    group('copyWith()', () {
      test('creates new task with updated name', () {
        final updated = task.copyWith(name: 'Exercise');

        expect(updated.name, equals('Exercise'));
        expect(updated.id, equals(task.id));
        expect(updated.colorHex, equals(task.colorHex));
      });

      test('does not mutate original', () {
        task.copyWith(name: 'New Name');
        expect(task.name, equals('Deep Work'));
      });
    });

    group('equality', () {
      test('tasks with same id are equal', () {
        final t2 = Task(
          id: 'task-001',
          name: 'Different Name',
          colorHex: '#000000',
          createdAt: DateTime.now(),
        );
        expect(task, equals(t2));
      });

      test('tasks with different ids are not equal', () {
        final t2 = task.copyWith(id: 'task-002');
        expect(task, isNot(equals(t2)));
      });
    });
  });

  group('Session serialization', () {
    final startTime = DateTime(2025, 3, 26, 9, 0, 0);
    final endTime = DateTime(2025, 3, 26, 10, 30, 0);

    final session = Session(
      id: 'session-001',
      taskId: 'task-001',
      startTime: startTime,
      endTime: endTime,
      durationSeconds: 5400,
      comment: 'Very productive',
    );

    group('toMap() / fromMap()', () {
      test('round-trips correctly', () {
        final map = session.toMap();
        final restored = Session.fromMap(map);

        expect(restored.id, equals(session.id));
        expect(restored.taskId, equals(session.taskId));
        expect(restored.durationSeconds, equals(session.durationSeconds));
        expect(restored.comment, equals(session.comment));
        expect(restored.endTime, isNotNull);
      });

      test('handles null endTime', () {
        final incomplete = Session(
          id: 'session-002',
          taskId: 'task-001',
          startTime: startTime,
          durationSeconds: 0,
        );
        final map = incomplete.toMap();
        final restored = Session.fromMap(map);

        expect(restored.endTime, isNull);
        expect(restored.isCompleted, isFalse);
      });

      test('handles null comment', () {
        final noComment = session.copyWith(clearComment: true);
        final map = noComment.toMap();
        final restored = Session.fromMap(map);

        expect(restored.comment, isNull);
      });

      test('toMap() includes all required fields', () {
        final map = session.toMap();

        expect(map.containsKey('id'), isTrue);
        expect(map.containsKey('task_id'), isTrue);
        expect(map.containsKey('start_time'), isTrue);
        expect(map.containsKey('end_time'), isTrue);
        expect(map.containsKey('duration_seconds'), isTrue);
        expect(map.containsKey('comment'), isTrue);
      });
    });

    group('toJson() / fromJson()', () {
      test('round-trips correctly for Supabase', () {
        final json = session.toJson();
        final restored = Session.fromJson(json);

        expect(restored.id, equals(session.id));
        expect(restored.taskId, equals(session.taskId));
        expect(restored.durationSeconds, equals(session.durationSeconds));
      });
    });

    group('isCompleted', () {
      test('returns true when endTime is set', () {
        expect(session.isCompleted, isTrue);
      });

      test('returns false when endTime is null', () {
        final incomplete = Session(
          id: 'x',
          taskId: 'y',
          startTime: DateTime.now(),
          durationSeconds: 0,
        );
        expect(incomplete.isCompleted, isFalse);
      });
    });

    group('duration getter', () {
      test('returns Duration equivalent of durationSeconds', () {
        expect(session.duration, equals(const Duration(seconds: 5400)));
      });
    });

    group('copyWith()', () {
      test('updates comment', () {
        final updated = session.copyWith(comment: 'Updated note');

        expect(updated.comment, equals('Updated note'));
        expect(updated.id, equals(session.id));
      });

      test('can clear endTime', () {
        final cleared = session.copyWith(clearEndTime: true);

        expect(cleared.endTime, isNull);
        expect(cleared.isCompleted, isFalse);
      });

      test('can clear comment', () {
        final cleared = session.copyWith(clearComment: true);

        expect(cleared.comment, isNull);
      });
    });

    group('equality', () {
      test('sessions with same id are equal', () {
        final s2 = Session(
          id: 'session-001',
          taskId: 'different-task',
          startTime: DateTime.now(),
          durationSeconds: 9999,
        );
        expect(session, equals(s2));
      });

      test('sessions with different ids are not equal', () {
        final s2 = session.copyWith(id: 'session-002');
        expect(session, isNot(equals(s2)));
      });
    });
  });
}
