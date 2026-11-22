import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/reminder_service.dart';
import '../utils/reminder_planner.dart';
import 'settings_provider.dart';

/// Situação dos lembretes de hidratação, exibida na tela Perfil e na Início.
enum StatusLembretes {
  /// O usuário não ligou os lembretes.
  desativados,

  /// Lembretes agendados no sistema.
  ativos,

  /// O usuário negou (ou retirou) a permissão de notificações.
  permissaoNegada,

  /// O aparelho/plataforma não oferece notificações (ex: navegador).
  indisponivel,

  /// Falha inesperada ao falar com o sistema de notificações.
  erro,
}

/// ESTADO GLOBAL: hidratação do dia e lembretes.
///
/// - Contador de copos do dia: alterado na Início, salvo no aparelho e
///   zerado automaticamente quando o dia muda.
/// - Lembretes: depende do [SettingsProvider] (meta, intervalo, ligado) e
///   do contador (para de lembrar quando a meta é atingida). Por isso a
///   agenda de notificações é refeita sempre que um dos dois muda.
class HydrationProvider extends ChangeNotifier {
  HydrationProvider(this._settings, this._lembretes, {DateTime Function()? relogio})
      : _agora = relogio ?? DateTime.now {
    // Mudou meta, intervalo ou liga/desliga no Perfil → refaz a agenda.
    _settings.addListener(_aoMudarConfiguracoes);
  }

  static const _kCopos = 'treinolog_agua_copos';
  static const _kDia = 'treinolog_agua_dia';

  final SettingsProvider _settings;
  final AgendadorLembretes _lembretes;
  final DateTime Function() _agora;

  int _copos = 0;
  String _dia = '';
  StatusLembretes _status = StatusLembretes.desativados;
  DateTime? _proximoLembrete;

  /// Fila que garante que dois reagendamentos nunca rodem ao mesmo tempo.
  Future<void> _fila = Future.value();

  int get copos => _copos;
  int get meta => _settings.metaAgua;
  bool get metaAtingida => _copos >= meta;
  double get progresso => meta == 0 ? 0 : (_copos / meta).clamp(0.0, 1.0);
  StatusLembretes get statusLembretes => _status;
  DateTime? get proximoLembrete => _proximoLembrete;
  bool get lembretesSuportados => _lembretes.suportado;

  static String _chaveDoDia(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    _copos = prefs.getInt(_kCopos) ?? 0;
    final diaSalvo = prefs.getString(_kDia);
    if (diaSalvo == null) {
      // Primeiro uso: grava o dia atual, para o contador zerar amanhã.
      _dia = _chaveDoDia(_agora());
      await prefs.setString(_kDia, _dia);
    } else {
      _dia = diaSalvo;
    }

    try {
      await _lembretes.inicializar();
    } catch (_) {
      // O recurso pode não existir neste aparelho; o status é ajustado no reagendamento.
    }

    await _verificarNovoDia(prefs);
    notifyListeners();
    await reagendar();
  }

  /// Chamado quando o app volta para a tela (ex: abriu de novo no dia seguinte,
  /// ou voltou das configurações do Android depois de mudar a permissão).
  Future<void> aoVoltarParaApp() async {
    final prefs = await SharedPreferences.getInstance();
    if (await _verificarNovoDia(prefs)) notifyListeners();
    await reagendar();
  }

  Future<void> adicionarCopo() async {
    final prefs = await SharedPreferences.getInstance();
    await _verificarNovoDia(prefs);
    _copos++;
    await prefs.setInt(_kCopos, _copos);
    notifyListeners();
    await reagendar(); // atualiza o texto dos lembretes ou para ao bater a meta
  }

  Future<void> removerCopo() async {
    if (_copos == 0) return;
    final prefs = await SharedPreferences.getInstance();
    _copos--;
    await prefs.setInt(_kCopos, _copos);
    notifyListeners();
    await reagendar();
  }

  /// Liga os lembretes: pede a permissão e, se concedida, agenda.
  /// Retorna o status final para a tela mostrar o feedback certo.
  Future<StatusLembretes> ativarLembretes() async {
    if (!_lembretes.suportado) {
      _definirStatus(StatusLembretes.indisponivel);
      return _status;
    }

    bool concedida;
    try {
      concedida = await _lembretes.solicitarPermissao();
    } catch (_) {
      _definirStatus(StatusLembretes.erro);
      return _status;
    }

    if (!concedida) {
      // Não liga a opção: sem permissão nenhum lembrete apareceria.
      _definirStatus(StatusLembretes.permissaoNegada);
      return _status;
    }

    await _settings.definirLembretesAtivos(true); // dispara _aoMudarConfiguracoes
    await reagendar();
    return _status;
  }

  Future<void> desativarLembretes() async {
    await _settings.definirLembretesAtivos(false);
    await reagendar();
  }

  /// Envia uma notificação na hora, para o usuário conferir se está funcionando.
  Future<StatusLembretes> enviarTeste() async {
    if (!_lembretes.suportado) {
      _definirStatus(StatusLembretes.indisponivel);
      return _status;
    }
    try {
      if (!await _lembretes.permissaoConcedida() && !await _lembretes.solicitarPermissao()) {
        _definirStatus(StatusLembretes.permissaoNegada);
        return StatusLembretes.permissaoNegada;
      }
      await _lembretes.mostrarAgora(
        titulo: 'Hora de beber água 💧',
        corpo: 'Lembrete de teste do TreinoLog. Você registrou $_copos de $meta copos hoje.',
      );
      return StatusLembretes.ativos;
    } catch (_) {
      return StatusLembretes.erro;
    }
  }

  Future<bool> abrirConfiguracoesDoSistema() => _lembretes.abrirConfiguracoes();

  /// Refaz a agenda de lembretes de acordo com o estado atual.
  Future<void> reagendar() {
    // catchError: uma falha anterior não pode travar os próximos reagendamentos.
    _fila = _fila.catchError((_) {}).then((_) => _reagendarAgora());
    return _fila;
  }

  Future<void> _reagendarAgora() async {
    if (!_lembretes.suportado) {
      _proximoLembrete = null;
      _definirStatus(StatusLembretes.indisponivel);
      return;
    }

    try {
      if (!_settings.lembretesAtivos) {
        await _lembretes.cancelarTodos();
        _proximoLembrete = null;
        _definirStatus(StatusLembretes.desativados);
        return;
      }

      // A permissão pode ter sido retirada nas configurações do Android.
      if (!await _lembretes.permissaoConcedida()) {
        await _lembretes.cancelarTodos();
        _proximoLembrete = null;
        _definirStatus(StatusLembretes.permissaoNegada);
        return;
      }

      final agenda = planejarLembretes(
        agora: _agora(),
        coposHoje: _copos,
        meta: meta,
        intervaloHoras: _settings.intervaloHoras,
        inicioHora: SettingsProvider.horaInicioLembretes,
        fimHora: SettingsProvider.horaFimLembretes,
      );
      await _lembretes.agendar(agenda);
      _proximoLembrete = agenda.isEmpty ? null : agenda.first.quando;
      _definirStatus(StatusLembretes.ativos);
    } catch (e) {
      debugPrint('Falha ao agendar lembretes: $e');
      _proximoLembrete = null;
      _definirStatus(StatusLembretes.erro);
    }
  }

  /// Zera o contador se o dia mudou. Retorna true se zerou.
  Future<bool> _verificarNovoDia(SharedPreferences prefs) async {
    final hoje = _chaveDoDia(_agora());
    if (hoje == _dia) return false;
    _dia = hoje;
    _copos = 0;
    await prefs.setString(_kDia, _dia);
    await prefs.setInt(_kCopos, 0);
    return true;
  }

  void _aoMudarConfiguracoes() {
    notifyListeners(); // a meta aparece na tela Início
    unawaited(reagendar());
  }

  void _definirStatus(StatusLembretes status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _settings.removeListener(_aoMudarConfiguracoes);
    super.dispose();
  }
}
