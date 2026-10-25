import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/exercise.dart';
import '../models/workout.dart';

/// Erro de comunicação com o backend, já com uma mensagem pronta
/// para ser mostrada ao usuário.
class ApiException implements Exception {
  final String mensagem;

  /// Código HTTP da resposta. Fica `null` quando nem houve resposta
  /// (servidor desligado, sem internet, tempo esgotado).
  final int? status;

  ApiException(this.mensagem, {this.status});

  bool get semConexao => status == null;

  @override
  String toString() => mensagem;
}

/// Camada de comunicação HTTP com a API do TreinoLog.
/// Só esta classe sabe URLs, métodos HTTP e formato JSON da API.
class ApiService {
  static final http.Client _client = http.Client();
  static const _headers = {'Content-Type': 'application/json'};

  static Uri _uri(String caminho) => Uri.parse('${ApiConfig.baseUrl}$caminho');

  /// GET /workouts
  static Future<List<Workout>> listarTreinos() async {
    final res = await _enviar(() => _client.get(_uri('/workouts')));
    final lista = _decodificar(res) as List<dynamic>;
    return lista
        .map((item) => Workout.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// POST /workouts — o servidor gera os ids do treino e dos exercícios.
  static Future<Workout> criarTreino(Workout treino) async {
    final corpo = jsonEncode({
      'data': treino.data.toIso8601String(),
      'exercicios': treino.exercicios.map(_exercicioParaApi).toList(),
    });

    final res = await _enviar(
      () => _client.post(_uri('/workouts'), headers: _headers, body: corpo),
    );
    return Workout.fromJson(_decodificar(res) as Map<String, dynamic>);
  }

  /// PUT /workouts/:workoutId/exercises/:exerciseId
  static Future<Workout> atualizarExercicio(String workoutId, Exercise exercicio) async {
    final res = await _enviar(
      () => _client.put(
        _uri('/workouts/$workoutId/exercises/${exercicio.id}'),
        headers: _headers,
        body: jsonEncode(_exercicioParaApi(exercicio)),
      ),
    );
    return Workout.fromJson(_decodificar(res) as Map<String, dynamic>);
  }

  /// DELETE /workouts/:id
  static Future<void> excluirTreino(String workoutId) async {
    await _enviar(() => _client.delete(_uri('/workouts/$workoutId')));
  }

  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _exercicioParaApi(Exercise e) => {
        'nome': e.nome,
        'series': e.series,
        'repeticoes': e.repeticoes,
        'carga': e.carga,
      };

  static dynamic _decodificar(http.Response res) {
    // bodyBytes + utf8 garante que acentos (ex: "Elevação") cheguem corretos.
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  /// Executa a requisição e converte qualquer falha em [ApiException].
  static Future<http.Response> _enviar(Future<http.Response> Function() requisicao) async {
    final res = await _executar(requisicao);
    if (res.statusCode >= 200 && res.statusCode < 300) return res;
    throw ApiException(_mensagemDeErro(res), status: res.statusCode);
  }

  /// Falhas de rede (servidor desligado, sem internet, demora) viram ApiException.
  static Future<http.Response> _executar(Future<http.Response> Function() requisicao) async {
    try {
      return await requisicao().timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw ApiException('O servidor demorou para responder. Tente novamente.');
    } catch (_) {
      throw ApiException(
        'Não foi possível conectar ao servidor. Verifique se o backend está rodando.',
      );
    }
  }

  /// Lê a mensagem de erro que o backend manda no formato
  /// { "erro": "...", "detalhes": ["..."] }.
  static String _mensagemDeErro(http.Response res) {
    try {
      final corpo = _decodificar(res) as Map<String, dynamic>;
      final detalhes = corpo['detalhes'];
      if (detalhes is List && detalhes.isNotEmpty) {
        return detalhes.first.toString();
      }
      if (corpo['erro'] is String) return corpo['erro'] as String;
    } catch (_) {
      // corpo não era JSON: cai na mensagem genérica abaixo
    }
    return 'Erro no servidor (código ${res.statusCode}).';
  }
}
