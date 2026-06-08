import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/task_service.dart';

final taskServiceProvider = Provider<TaskService>((ref) => TaskService());

final tasksProvider = AsyncNotifierProvider<TasksNotifier, List<Task>>(
  TasksNotifier.new,
);

class TasksNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    return ref.read(taskServiceProvider).getTasks();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(taskServiceProvider).getTasks(),
    );
  }

  Future<Task> createTask(String name, String colorHex) async {
    final service = ref.read(taskServiceProvider);
    final task = await service.createTask(name, colorHex);
    state = AsyncData([...state.valueOrNull ?? [], task]);
    return task;
  }

  Future<void> deleteTask(String id) async {
    final service = ref.read(taskServiceProvider);
    await service.deleteTask(id);
    state = AsyncData(
      (state.valueOrNull ?? []).where((t) => t.id != id).toList(),
    );
  }

  Future<Task?> getTaskById(String id) async {
    return ref.read(taskServiceProvider).getTaskById(id);
  }
}

final selectedTaskProvider = StateProvider<Task?>((ref) => null);
