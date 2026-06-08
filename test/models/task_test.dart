import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doro/models/task.dart';

void main() {
  final createdAt = DateTime(2024, 1, 15, 10, 30);

  Task makeTask({
    String id = 'task-1',
    String name = 'Deep Work',
    String colorHex = '#6C63FF',
  }) =>
      Task(id: id, name: name, colorHex: colorHex, createdAt: createdAt);

  // ---------------------------------------------------------------------------
  group('Task.color', () {
    test('parses hex with # prefix', () {
      expect(makeTask(colorHex: '#FF5733').color, const Color(0xFFFF5733));
    });

    test('parses hex without # prefix', () {
      expect(makeTask(colorHex: 'FF5733').color, const Color(0xFFFF5733));
    });

    test('full alpha is always set to FF', () {
      final color = makeTask(colorHex: '#000000').color;
      expect(color.a, 1.0); // alpha = 255 / 255 = 1.0 in flutter
    });
  });

  // ---------------------------------------------------------------------------
  group('Task.toMap / fromMap', () {
    test('roundtrip preserves all fields', () {
      final task = makeTask();
      final result = Task.fromMap(task.toMap());
      expect(result.id, task.id);
      expect(result.name, task.name);
      expect(result.colorHex, task.colorHex);
      expect(result.createdAt, task.createdAt);
    });

    test('toMap uses correct snake_case keys', () {
      final map = makeTask().toMap();
      expect(map['id'], 'task-1');
      expect(map['name'], 'Deep Work');
      expect(map['color_hex'], '#6C63FF');
      expect(map['created_at'], createdAt.toIso8601String());
    });

    test('fromMap with different values', () {
      final map = {
        'id': 'abc',
        'name': 'Exercise',
        'color_hex': '#FF0000',
        'created_at': DateTime(2025, 3, 1).toIso8601String(),
      };
      final task = Task.fromMap(map);
      expect(task.id, 'abc');
      expect(task.name, 'Exercise');
      expect(task.colorHex, '#FF0000');
    });
  });

  // ---------------------------------------------------------------------------
  group('Task.toJson / fromJson', () {
    test('roundtrip preserves all fields', () {
      final task = makeTask();
      final result = Task.fromJson(task.toJson());
      expect(result.id, task.id);
      expect(result.name, task.name);
      expect(result.colorHex, task.colorHex);
      expect(result.createdAt, task.createdAt);
    });

    test('toJson and toMap produce identical data', () {
      final task = makeTask();
      expect(task.toJson(), task.toMap());
    });
  });

  // ---------------------------------------------------------------------------
  group('Task.copyWith', () {
    test('no args returns identical values', () {
      final task = makeTask();
      final copy = task.copyWith();
      expect(copy.id, task.id);
      expect(copy.name, task.name);
      expect(copy.colorHex, task.colorHex);
      expect(copy.createdAt, task.createdAt);
    });

    test('updates name only', () {
      final updated = makeTask().copyWith(name: 'Reading');
      expect(updated.name, 'Reading');
      expect(updated.id, 'task-1');
    });

    test('updates all fields', () {
      final newDate = DateTime(2025, 6, 1);
      final updated = makeTask().copyWith(
        id: 'new-id',
        name: 'Meditation',
        colorHex: '#000000',
        createdAt: newDate,
      );
      expect(updated.id, 'new-id');
      expect(updated.name, 'Meditation');
      expect(updated.colorHex, '#000000');
      expect(updated.createdAt, newDate);
    });
  });

  // ---------------------------------------------------------------------------
  group('Task equality and hashCode', () {
    test('tasks with same id are equal regardless of other fields', () {
      final t1 = makeTask();
      final t2 = makeTask(name: 'Different Name', colorHex: '#000000');
      expect(t1, equals(t2));
    });

    test('tasks with different id are not equal', () {
      expect(makeTask(id: 'a'), isNot(equals(makeTask(id: 'b'))));
    });

    test('hashCode is consistent for same id', () {
      expect(makeTask().hashCode, makeTask().hashCode);
    });

    test('different ids produce different hashCodes', () {
      expect(makeTask(id: 'a').hashCode, isNot(makeTask(id: 'b').hashCode));
    });
  });

  // ---------------------------------------------------------------------------
  test('toString contains id and name', () {
    final s = makeTask().toString();
    expect(s, contains('task-1'));
    expect(s, contains('Deep Work'));
  });
}
