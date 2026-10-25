import 'package:flutter/foundation.dart';

/// Endereço do backend.
///
/// Por padrão:
/// - Emulador Android: http://10.0.2.2:3000 (10.0.2.2 é o "localhost" do PC visto de dentro do emulador)
/// - Web, Windows, iOS Simulator: http://localhost:3000
///
/// Para um celular físico na mesma Wi-Fi, rode com o IP do seu PC:
///   flutter run --dart-define=API_URL=http://192.168.0.10:3000
class ApiConfig {
  static const String _urlDefinida = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_urlDefinida.isNotEmpty) return _urlDefinida;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  /// Tempo máximo de espera por uma resposta do servidor.
  static const Duration timeout = Duration(seconds: 8);
}
