// Testes das regras de validação usadas nos formulários do app.
// Rodar com: flutter test

import 'package:flutter_test/flutter_test.dart';

import 'package:aprenda_brincando/models/exercise.dart';
import 'package:aprenda_brincando/models/workout.dart';
import 'package:aprenda_brincando/utils/validators.dart';

void main() {
  group('Validators.nome', () {
    test('rejeita nome vazio ou só com espaços', () {
      expect(Validators.nome(''), isNotNull);
      expect(Validators.nome('   '), isNotNull);
    });

    test('rejeita nome com mais de 60 caracteres', () {
      expect(Validators.nome('a' * 61), isNotNull);
    });

    test('aceita nome válido', () {
      expect(Validators.nome('Supino reto'), isNull);
    });
  });

  group('Validators.series e repeticoes', () {
    test('rejeita zero, vazio e valores acima do limite', () {
      expect(Validators.series('0'), isNotNull);
      expect(Validators.series(''), isNotNull);
      expect(Validators.series('51'), isNotNull);
      expect(Validators.repeticoes('0'), isNotNull);
      expect(Validators.repeticoes('501'), isNotNull);
    });

    test('aceita valores dentro do limite', () {
      expect(Validators.series('4'), isNull);
      expect(Validators.repeticoes('12'), isNull);
    });
  });

  group('Validators.carga', () {
    test('aceita zero (peso corporal) e decimais com vírgula ou ponto', () {
      expect(Validators.carga('0'), isNull);
      expect(Validators.carga('62,5'), isNull);
      expect(Validators.carga('62.5'), isNull);
      expect(Validators.parseCarga('62,5'), 62.5);
    });

    test('rejeita vazio, texto e valores acima de 1000 kg', () {
      expect(Validators.carga(''), isNotNull);
      expect(Validators.carga('abc'), isNotNull);
      expect(Validators.carga('1000.5'), isNotNull);
    });
  });

  test('Workout converte para JSON e volta sem perder dados', () {
    final original = Workout(
      id: 'abc',
      data: DateTime(2026, 10, 25, 10, 30),
      exercicios: [
        Exercise(id: 'e1', nome: 'Agachamento', series: 3, repeticoes: 12, carga: 80.5),
      ],
    );

    final copia = Workout.fromJson(original.toJson());

    expect(copia.id, original.id);
    expect(copia.data, original.data);
    expect(copia.exercicios.single.nome, 'Agachamento');
    expect(copia.exercicios.single.carga, 80.5);
  });
}
