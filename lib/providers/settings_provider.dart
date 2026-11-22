import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ESTADO GLOBAL: preferências do usuário.
///
/// Editadas na tela Perfil e usadas pela tela Início (saudação e meta de
/// água) e pelos lembretes de hidratação (meta, intervalo, ligado/desligado).
/// Ficam salvas no aparelho com SharedPreferences.
class SettingsProvider extends ChangeNotifier {
  static const _kNome = 'treinolog_perfil_nome';
  static const _kMeta = 'treinolog_agua_meta';
  static const _kLembretes = 'treinolog_lembretes_ativos';
  static const _kIntervalo = 'treinolog_lembretes_intervalo';

  static const int metaMinima = 4;
  static const int metaMaxima = 20;
  static const List<int> intervalosDisponiveis = [1, 2, 3, 4];

  /// Lembretes só são enviados dentro desta janela de horário (8h às 22h),
  /// para não acordar ninguém de madrugada.
  static const int horaInicioLembretes = 8;
  static const int horaFimLembretes = 22;

  String _nome = '';
  int _metaAgua = 8;
  bool _lembretesAtivos = false;
  int _intervaloHoras = 2;

  String get nome => _nome;
  int get metaAgua => _metaAgua;
  bool get lembretesAtivos => _lembretesAtivos;
  int get intervaloHoras => _intervaloHoras;

  /// Nome para exibir (usa um texto padrão enquanto o usuário não configura).
  String get nomeExibicao => _nome.isEmpty ? 'Atleta' : _nome;

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    _nome = prefs.getString(_kNome) ?? '';
    _metaAgua = (prefs.getInt(_kMeta) ?? 8).clamp(metaMinima, metaMaxima);
    _lembretesAtivos = prefs.getBool(_kLembretes) ?? false;
    final intervalo = prefs.getInt(_kIntervalo) ?? 2;
    _intervaloHoras = intervalosDisponiveis.contains(intervalo) ? intervalo : 2;
    notifyListeners();
  }

  Future<void> definirNome(String nome) async {
    _nome = nome.trim();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNome, _nome);
  }

  Future<void> definirMetaAgua(int meta) async {
    final nova = meta.clamp(metaMinima, metaMaxima);
    if (nova == _metaAgua) return;
    _metaAgua = nova;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMeta, _metaAgua);
  }

  Future<void> definirLembretesAtivos(bool ativos) async {
    if (ativos == _lembretesAtivos) return;
    _lembretesAtivos = ativos;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLembretes, ativos);
  }

  Future<void> definirIntervaloHoras(int horas) async {
    if (!intervalosDisponiveis.contains(horas) || horas == _intervaloHoras) return;
    _intervaloHoras = horas;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kIntervalo, horas);
  }
}
