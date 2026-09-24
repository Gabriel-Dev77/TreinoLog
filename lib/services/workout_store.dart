import 'package:flutter/foundation.dart';
import '../models/workout.dart';

// Essa classe guarda os treinos "em memória", enquanto o app está aberto.
// static = pertence à classe inteira, não a uma instância -> qualquer
// tela pode acessar essa mesma lista, sem precisar criar objetos
class WorkoutStore {
  static final List<Workout> workouts = [];

  // Avisa as telas interessadas (ex.: Início) quando a lista muda.
  // Como as abas ficam vivas no IndexedStack, elas não reconstroem sozinhas.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void addWorkout(Workout workout) {
    workouts.add(workout);
    changes.value++;
  }

  static void removeWorkout(Workout workout) {
    workouts.remove(workout);
    changes.value++;
  }
}
