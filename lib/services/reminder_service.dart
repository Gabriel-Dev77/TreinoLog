import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../utils/reminder_planner.dart';

/// Contrato do agendador de lembretes.
///
/// A interface permite trocar a implementação real (notificações do
/// Android) por uma falsa nos testes automatizados.
abstract class AgendadorLembretes {
  /// `false` quando o aparelho/plataforma não oferece o recurso (ex: navegador).
  bool get suportado;

  Future<void> inicializar();

  /// Permissão de notificações já concedida?
  Future<bool> permissaoConcedida();

  /// Pede a permissão ao usuário (Android 13+). Retorna se foi concedida.
  Future<bool> solicitarPermissao();

  /// Substitui todos os lembretes agendados pelos da lista.
  Future<void> agendar(List<LembreteAgendado> lembretes);

  Future<void> cancelarTodos();

  /// Mostra uma notificação imediatamente (usado no "Enviar lembrete de teste").
  Future<void> mostrarAgora({required String titulo, required String corpo});

  /// Abre a tela de configurações de notificações do app no sistema.
  Future<bool> abrirConfiguracoes();
}

/// RECURSO NATIVO: notificações locais do Android,
/// via pacote `flutter_local_notifications`.
///
/// As notificações são agendadas no próprio sistema operacional
/// (AlarmManager), então chegam mesmo com o app fechado.
class NotificationReminderService implements AgendadorLembretes {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _inicializado = false;

  static const _canalId = 'treinolog_hidratacao';
  static const _detalhes = NotificationDetails(
    android: AndroidNotificationDetails(
      _canalId,
      'Lembretes de hidratação',
      channelDescription: 'Lembra você de beber água ao longo do dia',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  /// Id da notificação de teste (fora da faixa dos lembretes agendados).
  static const _idTeste = 1;

  /// Nesta versão, os lembretes foram implementados e testados para Android.
  /// No navegador (Flutter Web) notificações agendadas não existem, e
  /// iOS/desktop não foram configurados — nesses casos o recurso aparece
  /// como "indisponível" e o restante do app funciona normalmente.
  @override
  bool get suportado => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<void> inicializar() async {
    if (!suportado || _inicializado) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        // Ícone das notificações: o próprio ícone do app.
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _inicializado = true;
  }

  Future<void> _garantirInicializado() async {
    if (!suportado) {
      throw UnsupportedError('Notificações não são suportadas neste dispositivo.');
    }
    if (!_inicializado) await inicializar();
  }

  @override
  Future<bool> permissaoConcedida() async {
    if (!suportado) return false;
    await _garantirInicializado();
    return await _android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<bool> solicitarPermissao() async {
    if (!suportado) return false;
    await _garantirInicializado();
    // No Android 13+ mostra a caixa "Permitir notificações?".
    // Em versões anteriores a permissão já vem concedida na instalação.
    final concedida = await _android?.requestNotificationsPermission();
    return concedida ?? await permissaoConcedida();
  }

  @override
  Future<void> agendar(List<LembreteAgendado> lembretes) async {
    await _garantirInicializado();
    // Remove a agenda anterior antes de criar a nova.
    await _plugin.cancelAllPendingNotifications();

    for (final l in lembretes) {
      await _plugin.zonedSchedule(
        id: l.id,
        title: l.titulo,
        body: l.corpo,
        // O horário é convertido para UTC: representa o mesmo instante,
        // sem precisar descobrir o nome do fuso horário do aparelho.
        scheduledDate: tz.TZDateTime.from(l.quando, tz.UTC),
        notificationDetails: _detalhes,
        // "Inexato": o Android pode atrasar alguns minutos para economizar
        // bateria, mas não exige a permissão especial de alarmes exatos.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelarTodos() async {
    if (!suportado) return;
    await _garantirInicializado();
    await _plugin.cancelAllPendingNotifications();
  }

  @override
  Future<void> mostrarAgora({required String titulo, required String corpo}) async {
    await _garantirInicializado();
    await _plugin.show(
      id: _idTeste,
      title: titulo,
      body: corpo,
      notificationDetails: _detalhes,
    );
  }

  @override
  Future<bool> abrirConfiguracoes() async {
    if (!suportado) return false;
    try {
      await _garantirInicializado();
      return await _android?.openAppNotificationSettings() ?? false;
    } catch (_) {
      return false;
    }
  }
}
