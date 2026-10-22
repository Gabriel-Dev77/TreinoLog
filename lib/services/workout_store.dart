
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise.dart';
import '../models/workout.dart';

/// Camada de persistência local da aplicação.
/// Utiliza SharedPreferences para armazenar os treinos em JSON.
class WorkoutStore {
  static const _storageKey = 'treinolog_workouts';

  // Cache em memória dos treinos.
  static List<Workout> workouts = [];

  static bool _carregado = false;

  // Notificador para atualizar automaticamente as telas.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// Notifica as telas quando os dados são alterados.
  static void notifyChanges() {
    changes.value++;
  }

  /// RECUPERAR: carrega os treinos salvos no dispositivo.
  static Future<void> init() async {
    if (_carregado) return;

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      final List<dynamic> decoded =
          jsonDecode(jsonString) as List<dynamic>;

      workouts = decoded
          .map(
            (item) => Workout.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    _carregado = true;

    // Atualiza as telas após carregar os dados.
    notifyChanges();
  }

  /// ARMAZENAR: salva os treinos no SharedPreferences.
  static Future<void> _salvar() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = jsonEncode(
      workouts.map((w) => w.toJson()).toList(),
    );

    await prefs.setString(_storageKey, jsonString);
  }

  /// CRIAR: adiciona um novo treino.
  static Future<void> addWorkout(Workout workout) async {
    workouts.add(workout);

    await _salvar();

    // Atualiza automaticamente a interface.
    notifyChanges();
  }

  /// REMOVER: exclui um treino pelo ID.
  static Future<void> removeWorkout(Workout workout) async {
    workouts.removeWhere((w) => w.id == workout.id);

    await _salvar();

    // Atualiza automaticamente a interface.
    notifyChanges();
  }

  /// ATUALIZAR: edita um exercício dentro de um treino.
  static Future<void> updateExercise(
    String workoutId,
    Exercise exercicioAtualizado,
  ) async {
    final index = workouts.indexWhere(
      (w) => w.id == workoutId,
    );

    if (index == -1) return;

    final workout = workouts[index];

    final novosExercicios = workout.exercicios
        .map(
          (e) => e.id == exercicioAtualizado.id
              ? exercicioAtualizado
              : e,
        )
        .toList();

    workouts[index] = workout.copyWith(
      exercicios: novosExercicios,
    );

    await _salvar();

    // Atualiza automaticamente a interface.
    notifyChanges();
  }

  /// Gera um identificador único baseado no instante atual.
  static String generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
