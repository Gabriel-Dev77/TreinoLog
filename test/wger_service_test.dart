// Testes da integração com o serviço externo wger (Etapa 6).
// As respostas da API são simuladas com MockClient, então os testes
// rodam sem internet. Rodar com: flutter test

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:aprenda_brincando/models/catalog_exercise.dart';
import 'package:aprenda_brincando/services/wger_service.dart';

/// Exemplo de item de `results`, no formato real do GET /exerciseinfo/ (resumido).
Map<String, dynamic> exercicioWger({
  int id = 73,
  bool comPortugues = true,
  bool comImagem = true,
}) =>
    {
      'id': id,
      'uuid': 'c0ab0f5f-0000-0000-0000-000000000000',
      'category': {'id': 11, 'name': 'Chest'},
      'muscles': [
        {'id': 4, 'name': 'Pectoralis major', 'name_en': 'Chest', 'is_front': true},
      ],
      'muscles_secondary': [
        {'id': 5, 'name': 'Triceps brachii', 'name_en': 'Triceps', 'is_front': false},
        {'id': 2, 'name': 'Anterior deltoid', 'name_en': '', 'is_front': true},
      ],
      'equipment': [
        {'id': 1, 'name': 'Barbell'},
        {'id': 8, 'name': 'Bench'},
      ],
      'images': comImagem
          ? [
              {
                'id': 1,
                'image': 'https://wger.de/media/exercise-images/73/bench.png',
                'is_main': true,
                'thumbnails': {
                  'small': 'https://wger.de/media/exercise-images/73/bench.small.png',
                  'medium': 'https://wger.de/media/exercise-images/73/bench.medium.png',
                },
              },
            ]
          : [],
      'translations': [
        {
          'id': 192,
          'name': 'Bench Press',
          'description': '<p>Lie on the bench.</p><ul><li>Lower the bar</li><li>Push up</li></ul>',
          'language': 2,
        },
        if (comPortugues)
          {
            'id': 900,
            'name': 'Supino reto',
            'description': '<p>Deite no banco &amp; empurre a barra.</p>',
            'language': 7,
          },
      ],
    };

http.Response jsonResponse(Object corpo, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(corpo)),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  group('CatalogExercise.fromWger', () {
    test('prefere o nome em português e traduz categoria, músculos e equipamentos', () {
      final ex = CatalogExercise.fromWger(exercicioWger());

      expect(ex.id, 73);
      expect(ex.nome, 'Supino reto');
      expect(ex.nomeIngles, 'Bench Press');
      expect(ex.categoria, 'Peito');
      expect(ex.musculos, ['Peitoral']);
      // Sem name_en, usa o nome em latim.
      expect(ex.musculosSecundarios, ['Tríceps', 'Anterior deltoid']);
      expect(ex.equipamentos, ['Barra', 'Banco']);
      expect(ex.descricao, 'Deite no banco & empurre a barra.');
      expect(ex.miniaturaUrl, endsWith('bench.small.png'));
    });

    test('usa o inglês quando não há tradução em português', () {
      final ex = CatalogExercise.fromWger(exercicioWger(comPortugues: false));
      expect(ex.nome, 'Bench Press');
      expect(ex.nomeIngles, isNull);
    });

    test('aceita exercício sem imagem', () {
      final ex = CatalogExercise.fromWger(exercicioWger(comImagem: false));
      expect(ex.imagemUrl, isNull);
      expect(ex.miniaturaUrl, isNull);
    });

    test('converte a descrição HTML em texto com lista', () {
      expect(
        CatalogExercise.limparHtml('<p>Lie on the bench.</p><ul><li>Lower</li><li>Push</li></ul>'),
        'Lie on the bench.\n\n• Lower\n\n• Push',
      );
    });

    test('rejeita item sem nome', () {
      expect(
        () => CatalogExercise.fromWger({'id': 1, 'translations': []}),
        throwsFormatException,
      );
    });
  });

  group('WgerService.buscarExercicios', () {
    test('SUCESSO: monta a URL de busca e devolve os exercícios', () async {
      late Uri chamada;
      WgerService.client = MockClient((req) async {
        chamada = req.url;
        return jsonResponse({
          'count': 1,
          'next': null,
          'previous': null,
          'results': [exercicioWger()],
        });
      });

      final lista = await WgerService.buscarExercicios('  supino ');

      expect(chamada.path, endsWith('/exerciseinfo/'));
      expect(chamada.queryParameters['name__search'], 'supino');
      expect(chamada.queryParameters['language__code'], 'pt,en');
      expect(chamada.queryParameters['limit'], '20');
      expect(lista.single.nome, 'Supino reto');
    });

    test('AUSÊNCIA DE DADOS: resposta sem resultados vira lista vazia', () async {
      WgerService.client = MockClient(
        (_) async => jsonResponse({'count': 0, 'next': null, 'previous': null, 'results': []}),
      );
      expect(await WgerService.buscarExercicios('xyzxyz'), isEmpty);
    });

    test('ignora itens incompletos sem derrubar a busca', () async {
      WgerService.client = MockClient(
        (_) async => jsonResponse({
          'results': [
            {'id': 1, 'translations': []},
            exercicioWger(id: 2),
          ],
        }),
      );
      final lista = await WgerService.buscarExercicios('supino');
      expect(lista.map((e) => e.id), [2]);
    });

    test('ERRO: status HTTP de erro vira WgerException', () async {
      WgerService.client = MockClient((_) async => http.Response('erro', 503));
      expect(
        () => WgerService.buscarExercicios('supino'),
        throwsA(isA<WgerException>().having((e) => e.status, 'status', 503)),
      );
    });

    test('ERRO: falha de rede vira WgerException com mensagem amigável', () async {
      WgerService.client = MockClient((_) async => throw http.ClientException('sem rede'));
      expect(
        () => WgerService.buscarExercicios('supino'),
        throwsA(isA<WgerException>()
            .having((e) => e.mensagem, 'mensagem', contains('internet'))),
      );
    });

    test('ERRO: corpo que não é JSON vira WgerException', () async {
      WgerService.client = MockClient((_) async => http.Response('<html>', 200));
      expect(() => WgerService.buscarExercicios('supino'), throwsA(isA<WgerException>()));
    });
  });

  group('WgerService.buscarPorId', () {
    test('SUCESSO: consulta /exerciseinfo/<id>/', () async {
      late Uri chamada;
      WgerService.client = MockClient((req) async {
        chamada = req.url;
        return jsonResponse(exercicioWger(id: 91));
      });

      final ex = await WgerService.buscarPorId(91);
      expect(chamada.path, endsWith('/exerciseinfo/91/'));
      expect(ex.id, 91);
    });

    test('ERRO: 404 informa que o exercício não existe', () async {
      WgerService.client = MockClient((_) async => jsonResponse({'detail': 'Not found.'}, 404));
      expect(
        () => WgerService.buscarPorId(999999),
        throwsA(isA<WgerException>().having((e) => e.status, 'status', 404)),
      );
    });
  });
}
