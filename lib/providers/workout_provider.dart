import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/api_service.dart';

/// ESTADO GLOBAL: lista de treinos do usuário.
///
/// Etapa 7: substitui a antiga classe estática `WorkoutStore`.
/// É um [ChangeNotifier] registrado no topo do app com o pacote `provider`,
/// e qualquer tela pode:
/// - ler e "assistir" os dados: `context.watch<WorkoutProvider>()` — a tela
///   é redesenhada automaticamente quando a lista muda;
/// - executar ações: `context.read<WorkoutProvider>().addWorkout(...)`.
///
/// Usado por: Início, Novo Treino, Histórico, Detalhes, Progresso, Perfil
/// e a faixa de "sem conexão".
///
/// Regras (mantidas da Etapa 5):
/// - o backend é a fonte oficial dos dados; a lista local só muda depois
///   que o servidor confirma a operação;
/// - a última lista recebida fica em cache no SharedPreferences, para o app
///   abrir e mostrar os treinos mesmo sem conexão.
class WorkoutProvider extends ChangeNotifier {
  static const _cacheKey = 'treinolog_workouts';

  List<Workout> _workouts = [];
  bool _offline = false;
  Future<void>? _sincronizacaoEmAndamento;

  /// Treinos em ordem cronológica (somente leitura para as telas).
  List<Workout> get workouts => List.unmodifiable(_workouts);

  /// `true` quando a última tentativa de falar com o servidor falhou por falta de conexão.
  bool get offline => _offline;

  /// Mostra rápido o que está no cache e, em segundo plano, busca a versão
  /// atualizada no servidor.
  Future<void> init() async {
    await _carregarCache();
    unawaited(refresh().then((_) {}, onError: (_) {}));
  }

  /// RECUPERAR: busca a lista de treinos no servidor.
  /// Se já houver uma busca em andamento, reaproveita a mesma.
  Future<void> refresh() {
    return _sincronizacaoEmAndamento ??=
        _buscarDoServidor().whenComplete(() => _sincronizacaoEmAndamento = null);
  }

  Future<void> _buscarDoServidor() async {
    try {
      _workouts = await ApiService.listarTreinos();
      _ordenar();
      _offline = false;
      await _salvarCache();
    } on ApiException catch (e) {
      _registrarFalha(e);
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// CRIAR: envia o treino para a API e guarda a versão devolvida.
  Future<void> addWorkout(Workout workout) async {
    try {
      final criado = await ApiService.criarTreino(workout);
      _workouts.add(criado);
      _ordenar();
      _offline = false;
    } on ApiException catch (e) {
      _registrarFalha(e);
      notifyListeners();
      rethrow;
    }
    await _salvarCache();
    notifyListeners();
  }

  /// REMOVER: exclui o treino no servidor.
  Future<void> removeWorkout(Workout workout) async {
    try {
      await ApiService.excluirTreino(workout.id);
      _offline = false;
    } on ApiException catch (e) {
      // 404 = o treino já não existe no servidor; basta tirar da tela.
      if (e.status != 404) {
        _registrarFalha(e);
        notifyListeners();
        rethrow;
      }
    }
    _workouts.removeWhere((w) => w.id == workout.id);
    await _salvarCache();
    notifyListeners();
  }

  /// ATUALIZAR: edita um exercício de um treino no servidor.
  Future<void> updateExercise(String workoutId, Exercise exercicioAtualizado) async {
    try {
      final treinoAtualizado =
          await ApiService.atualizarExercicio(workoutId, exercicioAtualizado);
      final index = _workouts.indexWhere((w) => w.id == workoutId);
      if (index != -1) _workouts[index] = treinoAtualizado;
      _offline = false;
    } on ApiException catch (e) {
      _registrarFalha(e);
      notifyListeners();
      rethrow;
    }
    await _salvarCache();
    notifyListeners();
  }

  /// Busca um treino pelo id (ou null se não existir mais).
  Workout? findById(String id) {
    for (final w in _workouts) {
      if (w.id == id) return w;
    }
    return null;
  }

  /// Treinos registrados no mesmo dia de [dia].
  List<Workout> treinosDoDia(DateTime dia) => _workouts
      .where((t) => t.data.year == dia.year && t.data.month == dia.month && t.data.day == dia.day)
      .toList();

  /// Gera um id temporário, usado só enquanto o exercício ainda não foi
  /// enviado ao servidor (na lista da tela "Novo Treino").
  static String generateId() => DateTime.now().microsecondsSinceEpoch.toString();

  // ---------------------------------------------------------------------------
  // Cache local (SharedPreferences)

  Future<void> _carregarCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString != null) {
        final decoded = jsonDecode(jsonString) as List<dynamic>;
        _workouts = decoded
            .map((item) => Workout.fromJson(item as Map<String, dynamic>))
            .toList();
        _ordenar();
      }
    } catch (_) {
      // Cache corrompido ou de formato antigo: ignora e espera o servidor.
      _workouts = [];
    }
    notifyListeners();
  }

  Future<void> _salvarCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(_workouts.map((w) => w.toJson()).toList()),
    );
  }

  void _ordenar() => _workouts.sort((a, b) => a.data.compareTo(b.data));

  void _registrarFalha(ApiException e) {
    if (e.semConexao) _offline = true;
  }
}
