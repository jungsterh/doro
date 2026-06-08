import '../core/constants/app_constants.dart';
import '../models/task.dart';
import 'database_service.dart';

class TaskService {
  final DatabaseService _db;

  TaskService({DatabaseService? db}) : _db = db ?? DatabaseService.instance;

  Future<List<Task>> getTasks() async {
    return _db.getTasks();
  }

  Future<Task?> getTaskById(String id) async {
    return _db.getTaskById(id);
  }

  Future<Task> createTask(String name, String colorHex) async {
    final id = _generateId();
    final task = Task(
      id: id,
      name: name.trim(),
      colorHex: colorHex,
      createdAt: DateTime.now(),
    );
    await _db.insertTask(task);
    return task;
  }

  Future<Task> updateTask(Task task) async {
    await _db.updateTask(task);
    return task;
  }

  Future<void> deleteTask(String id) async {
    await _db.deleteTask(id);
  }

  String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString() +
        _randomSuffix();
  }

  String _randomSuffix() {
    // Simple pseudo-random suffix
    final now = DateTime.now().microsecondsSinceEpoch;
    return (now % 100000).toString().padLeft(5, '0');
  }

  Future<String> getRandomDefaultColor(List<Task> existing) async {
    final usedColors = existing.map((t) => t.colorHex).toSet();
    final available = AppConstants.defaultColors
        .where((c) => !usedColors.contains(c))
        .toList();
    if (available.isNotEmpty) return available.first;
    return AppConstants.defaultColors[
        existing.length % AppConstants.defaultColors.length];
  }
}
