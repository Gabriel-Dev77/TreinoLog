import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/wger_config.dart';
import '../models/catalog_exercise.dart';

/// Erro ao consultar o catálogo wger, com mensagem pronta para o usuário.
class WgerException implements Exception {
  final String mensagem;
  final int? status;

  WgerException(this.mensagem, {this.status});

  @override
  String toString() => mensagem;
}

/// Comunicação com o serviço externo wger (https://wger.de).
///
/// Só faz CONSULTAS (GET). Os endpoints usados são públicos e não exigem
/// autenticação.
class WgerService {
  /// O cliente HTTP pode ser trocado nos testes por um `MockClient`,
  /// para simular respostas sem acessar a internet.
  static http.Client client = http.Client();

  static const _headers = {'Accept': 'application/json'};

  /// CONSULTA: busca exercícios pelo nome.
  ///
  /// `GET /exerciseinfo/?name__search=<termo>&language__code=pt,en&limit=20`
  ///
  /// Retorna lista vazia quando nada é encontrado (estado "ausência de dados").
  static Future<List<CatalogExercise>> buscarExercicios(String termo) async {
    final uri = Uri.parse('${WgerConfig.baseUrl}/exerciseinfo/').replace(
      queryParameters: {
        'name__search': termo.trim(),
        'language__code': WgerConfig.idiomas.join(','),
        'limit': '${WgerConfig.limiteResultados}',
      },
    );

    final corpo = await _get(uri);
    if (corpo is! Map<String, dynamic> || corpo['results'] is! List) {
      throw WgerException('O catálogo respondeu em um formato inesperado.');
    }

    final resultados = <CatalogExercise>[];
    for (final item in corpo['results'] as List) {
      if (item is! Map<String, dynamic>) continue;
      try {
        resultados.add(CatalogExercise.fromWger(item));
      } on FormatException {
        // Item incompleto no catálogo (sem nome, por exemplo): ignora só ele.
      }
    }
    return resultados;
  }

  /// CONSULTA: detalhes de um exercício pelo id.
  ///
  /// `GET /exerciseinfo/<id>/`
  static Future<CatalogExercise> buscarPorId(int id) async {
    final corpo = await _get(Uri.parse('${WgerConfig.baseUrl}/exerciseinfo/$id/'));
    if (corpo is! Map<String, dynamic>) {
      throw WgerException('O catálogo respondeu em um formato inesperado.');
    }
    try {
      return CatalogExercise.fromWger(corpo);
    } on FormatException {
      throw WgerException('Os dados deste exercício estão incompletos no catálogo.');
    }
  }

  // ---------------------------------------------------------------------------

  static Future<dynamic> _get(Uri uri) async {
    final http.Response res;
    try {
      res = await client.get(uri, headers: _headers).timeout(WgerConfig.timeout);
    } on TimeoutException {
      throw WgerException('O catálogo de exercícios demorou para responder. Tente novamente.');
    } catch (_) {
      throw WgerException(
        'Não foi possível acessar o catálogo de exercícios. Verifique sua conexão com a internet.',
      );
    }

    if (res.statusCode == 404) {
      throw WgerException('Exercício não encontrado no catálogo.', status: 404);
    }
    if (res.statusCode == 429) {
      throw WgerException(
        'Muitas consultas ao catálogo em pouco tempo. Aguarde um instante.',
        status: 429,
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw WgerException(
        'O catálogo está indisponível no momento (código ${res.statusCode}).',
        status: res.statusCode,
      );
    }

    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      throw WgerException('O catálogo respondeu em um formato inesperado.');
    }
  }
}
