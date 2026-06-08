import 'package:flutter/material.dart';

class Task {
  final String id;
  final String name;
  final String colorHex;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.createdAt,
  });

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Task copyWith({
    String? id,
    String? name,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // SQLite serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Supabase / JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['color_hex'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Task(id: $id, name: $name, colorHex: $colorHex)';
}
