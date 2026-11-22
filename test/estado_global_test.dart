// Testes da Etapa 7: estado global (Provider) e lembretes de hidratação.
// O plugin de notificações é substituído por um agendador falso, então os
// testes rodam sem celular. Rodar com: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aprenda_brincando/models/exercise.dart';
import 'package:aprenda_brincando/models/workout.dart';
import 'package:aprenda_brincando/providers/hydration_provider.dart';
import 'package:aprenda_brincando/providers/settings_provider.dart';
import 'package:aprenda_brincando/services/reminder_service.dart';
import 'package:aprenda_brincando/services/share_service.dart';
import 'package:aprenda_brincando/utils/reminder_planner.dart';

/// Agendador falso: guarda o que seria agendado no Android.
class AgendadorFalso implements AgendadorLembretes {
  AgendadorFalso({this.suportado = true, this.permitido = true, this.usuarioPermite = true});

  @override
  final bool suportado;
  bool permitido;
  bool usuarioPermite;
  List<LembreteAgendado> agendados = [];
  int notificacoesImediatas = 0;

  @override
  Future<void> inicializar() async {}

  @override
  Future<bool> permissaoConcedida() async => permitido;

  @override
  Future<bool> solicitarPermissao() async {
    permitido = usuarioPermite;
    return permitido;
  }

  @override
  Future<void> agendar(List<LembreteAgendado> lembretes) async => agendados = lembretes;

  @override
  Future<void> cancelarTodos() async => agendados = [];

  @override
  Future<void> mostrarAgora({required String titulo, required String corpo}) async =>
      notificacoesImediatas++;

  @override
  Future<bool> abrirConfiguracoes() async => true;
}

void main() {
  group('planejarLembretes', () {
    test('agenda só os horários de hoje que ainda não passaram, e os de amanhã', () {
      final lista = planejarLembretes(
        agora: DateTime(2026, 11, 22, 13, 30),
        coposHoje: 3,
        meta: 8,
        intervaloHoras: 2,
      );
      final horasHoje = lista.where((l) => l.quando.day == 22).map((l) => l.quando.hour);
      final horasAmanha = lista.where((l) => l.quando.day == 23).map((l) => l.quando.hour);

      expect(horasHoje, [14, 16, 18, 20, 22]);
      expect(horasAmanha, [8, 10, 12, 14, 16, 18, 20, 22]);
      expect(lista.first.corpo, contains('3 de 8 copos'));
      // ids únicos e em sequência
      expect(lista.map((l) => l.id).toSet().length, lista.length);
    });

    test('não lembra hoje quando a meta já foi atingida', () {
      final lista = planejarLembretes(
        agora: DateTime(2026, 11, 22, 9),
        coposHoje: 8,
        meta: 8,
        intervaloHoras: 3,
      );
      expect(lista.every((l) => l.quando.day == 23), isTrue);
      expect(lista.first.quando, DateTime(2026, 11, 23, 8));
    });

    test('vira o mês corretamente', () {
      final lista = planejarLembretes(
        agora: DateTime(2026, 11, 30, 23),
        coposHoje: 0,
        meta: 8,
        intervaloHoras: 4,
      );
      expect(lista.first.quando, DateTime(2026, 12, 1, 8));
    });
  });

  group('HydrationProvider (estado global)', () {
    late DateTime agora;
    late SettingsProvider settings;
    late AgendadorFalso agendador;

    Future<HydrationProvider> criar({AgendadorFalso? falso}) async {
      agendador = falso ?? AgendadorFalso();
      settings = SettingsProvider();
      await settings.carregar();
      final p = HydrationProvider(settings, agendador, relogio: () => agora);
      await p.carregar();
      return p;
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      agora = DateTime(2026, 11, 22, 10, 30);
    });

    test('conta copos e salva no aparelho', () async {
      final agua = await criar();
      await agua.adicionarCopo();
      await agua.adicionarCopo();
      expect(agua.copos, 2);

      // Simula fechar e abrir o app: um novo provider lê o valor salvo.
      final reaberto = await criar();
      expect(reaberto.copos, 2);
    });

    test('zera o contador quando o dia muda', () async {
      final agua = await criar();
      await agua.adicionarCopo();
      agora = DateTime(2026, 11, 23, 7);
      await agua.aoVoltarParaApp();
      expect(agua.copos, 0);
    });

    test('zera também quando o app é aberto só no dia seguinte', () async {
      final agua = await criar();
      await agua.adicionarCopo();

      agora = DateTime(2026, 11, 23, 9); // app fechado e reaberto amanhã
      final amanha = await criar();
      expect(amanha.copos, 0);
    });

    test('a meta vem do SettingsProvider e reage a mudanças no Perfil', () async {
      final agua = await criar();
      var avisos = 0;
      agua.addListener(() => avisos++);

      await settings.definirMetaAgua(10);
      expect(agua.meta, 10);
      expect(avisos, greaterThan(0)); // a tela Início seria redesenhada
    });

    test('ligar lembretes pede permissão e agenda', () async {
      final agua = await criar(falso: AgendadorFalso(permitido: false));
      final status = await agua.ativarLembretes();

      expect(status, StatusLembretes.ativos);
      expect(settings.lembretesAtivos, isTrue);
      expect(agendador.agendados, isNotEmpty);
      expect(agua.proximoLembrete, DateTime(2026, 11, 22, 12));
    });

    test('permissão negada: não liga e informa o motivo', () async {
      final agua = await criar(
        falso: AgendadorFalso(permitido: false, usuarioPermite: false),
      );
      final status = await agua.ativarLembretes();

      expect(status, StatusLembretes.permissaoNegada);
      expect(settings.lembretesAtivos, isFalse);
      expect(agendador.agendados, isEmpty);
    });

    test('permissão retirada nas configurações: cancela os lembretes', () async {
      final agua = await criar();
      await agua.ativarLembretes();
      expect(agendador.agendados, isNotEmpty);

      agendador.permitido = false; // usuário desligou nas configurações do Android
      await agua.aoVoltarParaApp();

      expect(agua.statusLembretes, StatusLembretes.permissaoNegada);
      expect(agendador.agendados, isEmpty);
    });

    test('ao atingir a meta, para de lembrar hoje', () async {
      final agua = await criar();
      await settings.definirMetaAgua(4);
      await agua.ativarLembretes();
      for (var i = 0; i < 4; i++) {
        await agua.adicionarCopo();
      }
      expect(agua.metaAtingida, isTrue);
      expect(agendador.agendados.any((l) => l.quando.day == 22), isFalse);
      expect(agendador.agendados.any((l) => l.quando.day == 23), isTrue);
    });

    test('recurso indisponível (ex: navegador): app continua funcionando', () async {
      final agua = await criar(falso: AgendadorFalso(suportado: false));
      expect(agua.statusLembretes, StatusLembretes.indisponivel);
      expect(await agua.ativarLembretes(), StatusLembretes.indisponivel);

      await agua.adicionarCopo(); // o contador de água funciona normalmente
      expect(agua.copos, 1);
    });

    test('desligar lembretes cancela a agenda', () async {
      final agua = await criar();
      await agua.ativarLembretes();
      await agua.desativarLembretes();
      expect(agendador.agendados, isEmpty);
      expect(agua.statusLembretes, StatusLembretes.desativados);
    });
  });

  test('ShareService monta o resumo do treino', () {
    final treino = Workout(
      id: 't1',
      data: DateTime(2026, 11, 22, 18, 5),
      exercicios: [
        Exercise(id: 'e1', nome: 'Supino reto', series: 4, repeticoes: 10, carga: 60),
        Exercise(id: 'e2', nome: 'Flexão', series: 3, repeticoes: 15, carga: 0),
      ],
    );

    final texto = ShareService.textoDoTreino(treino);
    expect(texto, contains('22/11/2026 às 18:05'));
    expect(texto, contains('• Supino reto: 4x10 com 60 kg'));
    expect(texto, contains('• Flexão: 3x15 (peso corporal)'));
    expect(texto, contains('volume total: 2400 kg'));
  });
}
