import '../models/workout.dart';

// Essa classe guarda os treinos "em memória", enquanto o app está aberto.
// static = pertence à classe inteira, não a uma instância -> qualquer
// tela pode acessar essa mesma lista, sem precisar criar objetos
class WorkoutStore {
  static final List<Workout> workouts = [];

  static void addWorkout(Workout workout) {
    workouts.add(workout);
  }
}