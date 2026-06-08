class Session {
  final String id;
  final String taskId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final String? comment;

  const Session({
    required this.id,
    required this.taskId,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    this.comment,
  });

  bool get isCompleted => endTime != null;

  Duration get duration => Duration(seconds: durationSeconds);

  Session copyWith({
    String? id,
    String? taskId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    String? comment,
    bool clearEndTime = false,
    bool clearComment = false,
  }) {
    return Session(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      startTime: startTime ?? this.startTime,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      durationSeconds: durationSeconds ?? this.durationSeconds,
      comment: clearComment ? null : (comment ?? this.comment),
    );
  }

  // SQLite serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'comment': comment,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      durationSeconds: map['duration_seconds'] as int,
      comment: map['comment'] as String?,
    );
  }

  // Supabase / JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'comment': comment,
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int,
      comment: json['comment'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Session(id: $id, taskId: $taskId, duration: $durationSeconds s)';
}
