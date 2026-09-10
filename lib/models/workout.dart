import 'exercise.dart';

// Um Treino tem uma data e uma lista de exercícios feitos naquele dia
class Workout {
  final DateTime data;
  final List<Exercise> exercicios;

  Workout({
    required this.data,
    required this.exercicios,
  });
}