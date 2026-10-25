import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise.dart';
import '../models/workout.dart';
import 'api_service.dart';

/// Estado dos treinos no app.
///
/// Etapa 5: o backend passou a ser a fonte oficial dos dados.
/// - Toda criação, edição e exclusão é enviada para a API.
/// - Só depois que o servidor confirma, a lista local é atualizada.
/// - Uma cópia da última lista recebida fica salva no SharedPreferences
///   (cache). Se o servidor estiver fora do ar, o app continua mostrando
///   os treinos já conhecidos, em modo somente leitura.
class WorkoutStore {
  static const _cacheKey = 'treinolog_workouts';

  /// Treinos conhecidos pelo app, em ordem cronológica.
  static List<Workout> workouts = [];

  /// Avisa as telas que a lista mudou.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// `true` quando a última tentativa de falar com o servidor falhou por falta de conexão.
  static final ValueNotifier<bool> offline = ValueNotifier<bool>(false);

  static Future<void>? _sincronizacaoEmAndamento;

  static void notifyChanges() {
    changes.value++;
  }

  /// Chamado no main(): mostra rápido o que está no cache e,
  /// em segundo plano, busca a versão atualizada no servidor.
  static Future<void> init() async {
    await _carregarCache();
    unawaited(refresh().then((_) {}, onError: (_) {}));
  }

  /// RECUPERAR: busca a lista de treinos no servidor.
  /// Se já houver uma busca em andamento, reaproveita a mesma.
  static Future<void> refresh() {
    return _sincronizacaoEmAndamento ??=
        _buscarDoServidor().whenComplete(() => _sincronizacaoEmAndamento = null);
  }

  static Future<void> _buscarDoServidor() async {
    try {
      workouts = await ApiService.listarTreinos();
      _ordenar();
      offline.value = false;
      await _salvarCache();
    } on ApiException catch (e) {
      _registrarFalha(e);
      rethrow;
    } finally {
      notifyChanges();
    }
  }

  /// CRIAR: envia o treino para a API e guarda a versão devolvida
  /// (já com os ids gerados pelo servidor).
  static Future<void> addWorkout(Workout workout) async {
    try {
      final criado = await ApiService.criarTreino(workout);
      workouts.add(criado);
      _ordenar();
      offline.value = false;
    } on ApiException catch (e) {
      _registrarFalha(e);
      rethrow;
    }
    await _salvarCache();
    notifyChanges();
  }

  /// REMOVER: exclui o treino no servidor.
  static Future<void> removeWorkout(Workout workout) async {
    try {
      await ApiService.excluirTreino(workout.id);
      offline.value = false;
    } on ApiException catch (e) {
      // 404 = o treino já não existe no servidor; basta tirar da tela.
      if (e.status != 404) {
        _registrarFalha(e);
        rethrow;
      }
    }
    workouts.removeWhere((w) => w.id == workout.id);
    await _salvarCache();
    notifyChanges();
  }

  /// ATUALIZAR: edita um exercício de um treino no servidor.
  static Future<void> updateExercise(String workoutId, Exercise exercicioAtualizado) async {
    try {
      final treinoAtualizado =
          await ApiService.atualizarExercicio(workoutId, exercicioAtualizado);
      final index = workouts.indexWhere((w) => w.id == workoutId);
      if (index != -1) workouts[index] = treinoAtualizado;
      offline.value = false;
    } on ApiException catch (e) {
      _registrarFalha(e);
      rethrow;
    }
    await _salvarCache();
    notifyChanges();
  }

  /// Busca um treino pelo id na lista local (ou null se não existir mais).
  static Workout? findById(String id) {
    for (final w in workouts) {
      if (w.id == id) return w;
    }
    return null;
  }

  /// Gera um id temporário, usado só enquanto o exercício ainda não foi
  /// enviado ao servidor (na lista da tela "Novo Treino").
  static String generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  // ---------------------------------------------------------------------------
  // Cache local (SharedPreferences)

  static Future<void> _carregarCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString != null) {
        final decoded = jsonDecode(jsonString) as List<dynamic>;
        workouts = decoded
            .map((item) => Workout.fromJson(item as Map<String, dynamic>))
            .toList();
        _ordenar();
      }
    } catch (_) {
      // Cache corrompido ou de formato antigo: ignora e espera o servidor.
      workouts = [];
    }
    notifyChanges();
  }

  static Future<void> _salvarCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(workouts.map((w) => w.toJson()).toList()),
    );
  }

  static void _ordenar() {
    workouts.sort((a, b) => a.data.compareTo(b.data));
  }

  static void _registrarFalha(ApiException e) {
    if (e.semConexao) offline.value = true;
  }
}
