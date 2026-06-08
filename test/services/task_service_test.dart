import 'package:flutter_test/flutter_test.dart';
import 'package:doro/models/task.dart';
import 'package:doro/services/database_service.dart';
import 'package:doro/services/task_service.dart';

// Manual fake for DatabaseService
class FakeDatabaseService extends Fake implements DatabaseService {
  List<Task> tasks = [];
  Task? taskToReturn;
  bool insertCalled = false;
  bool updateCalled = false;
  bool deleteCalled = false;
  String? deletedId;

  @override
  Future<List<Task>> getTasks() async => tasks;

  @override
  Future<Task?> getTaskById(String id) async => taskToReturn;

  @override
  Future<void> insertTask(Task task) async {
    insertCalled = true;
    tasks.add(task);
  }

  @override
  Future<void> updateTask(Task task) async {
    updateCalled = true;
    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx >= 0) tasks[idx] = task;
  }

  @override
  Future<void> deleteTask(String id) async {
    deleteCalled = true;
    deletedId = id;
    tasks.removeWhere((t) => t.id == id);
  }
}

void main() {
  late FakeDatabaseService fakeDb;
  late TaskService taskService;

  setUp(() {
    fakeDb = FakeDatabaseService();
    taskService = TaskService(db: fakeDb);
  });

  group('TaskService', () {
    final sampleTask = Task(
      id: '123',
      name: 'Deep Work',
      colorHex: '#6C63FF',
      createdAt: DateTime(2025, 1, 1),
    );

    group('getTasks()', () {
      test('returns list of tasks from database', () async {
        fakeDb.tasks = [sampleTask];

        final tasks = await taskService.getTasks();

        expect(tasks, equals([sampleTask]));
      });

      test('returns empty list when no tasks', () async {
        fakeDb.tasks = [];

        final tasks = await taskService.getTasks();

        expect(tasks, isEmpty);
      });
    });

    group('getTaskById()', () {
      test('returns task when found', () async {
        fakeDb.taskToReturn = sampleTask;

        final task = await taskService.getTaskById('123');

        expect(task, equals(sampleTask));
      });

      test('returns null when not found', () async {
        fakeDb.taskToReturn = null;

        final task = await taskService.getTaskById('999');

        expect(task, isNull);
      });
    });

    group('createTask()', () {
      test('creates task with given name and color', () async {
        final task = await taskService.createTask('Deep Work', '#6C63FF');

        expect(task.name, equals('Deep Work'));
        expect(task.colorHex, equals('#6C63FF'));
        expect(task.id, isNotEmpty);
        expect(task.createdAt, isNotNull);
        expect(fakeDb.insertCalled, isTrue);
      });

      test('trims whitespace from task name', () async {
        final task =
            await taskService.createTask('  Deep Work  ', '#6C63FF');

        expect(task.name, equals('Deep Work'));
      });

      test('assigns provided color hex', () async {
        final task = await taskService.createTask('Focus', '#FF6584');

        expect(task.colorHex, equals('#FF6584'));
      });
    });

    group('deleteTask()', () {
      test('calls database delete with correct id', () async {
        await taskService.deleteTask('123');

        expect(fakeDb.deleteCalled, isTrue);
        expect(fakeDb.deletedId, equals('123'));
      });
    });

    group('updateTask()', () {
      test('calls database update and returns updated task', () async {
        fakeDb.tasks = [sampleTask];

        final result = await taskService.updateTask(sampleTask);

        expect(result, equals(sampleTask));
        expect(fakeDb.updateCalled, isTrue);
      });
    });

    group('getRandomDefaultColor()', () {
      test('returns first color when no tasks exist', () async {
        final color = await taskService.getRandomDefaultColor([]);

        expect(color, isNotEmpty);
        expect(color.startsWith('#'), isTrue);
      });

      test('avoids colors already used by existing tasks', () async {
        final existingTasks = [
          Task(
            id: '1',
            name: 'Task 1',
            colorHex: '#6C63FF',
            createdAt: DateTime.now(),
          ),
        ];

        final color =
            await taskService.getRandomDefaultColor(existingTasks);
        expect(color, isNot(equals('#6C63FF')));
      });

      test('returns a valid hex color string', () async {
        final color = await taskService.getRandomDefaultColor([]);

        expect(color, matches(RegExp(r'^#[0-9A-Fa-f]{6}$')));
      });
    });
  });
}
