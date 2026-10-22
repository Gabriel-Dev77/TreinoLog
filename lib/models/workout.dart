import 'exercise.dart';

class Workout {
  final String id;
  final DateTime data;
  final List<Exercise> exercicios;

  Workout({
    required this.id,
    required this.data,
    required this.exercicios,
  });

  Workout copyWith({
    DateTime? data,
    List<Exercise>? exercicios,
  }) {
    return Workout(
      id: id,
      data: data ?? this.data,
      exercicios: exercicios ?? this.exercicios,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data.toIso8601String(),
      'exercicios': exercicios.map((e) => e.toJson()).toList(),
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      data: DateTime.parse(json['data'] as String),
      exercicios: (json['exercicios'] as List)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}