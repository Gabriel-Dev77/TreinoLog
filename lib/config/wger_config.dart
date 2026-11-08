/// Configuração do serviço externo wger (catálogo de exercícios).
///
/// A API pública do wger NÃO exige chave nem login para consultar
/// exercícios, então nenhuma credencial é guardada no código.
///
/// Para usar outra instância do wger (ex: uma instalação própria):
///   flutter run --dart-define=WGER_URL=https://meu-wger.exemplo.com/api/v2
class WgerConfig {
  static const String baseUrl = String.fromEnvironment(
    'WGER_URL',
    defaultValue: 'https://wger.de/api/v2',
  );

  /// Idiomas pedidos à API, em ordem de preferência para exibir o nome.
  /// O catálogo tem bem mais exercícios em inglês do que em português,
  /// por isso os dois são consultados.
  static const List<String> idiomas = ['pt', 'en'];

  /// Ids dos idiomas no wger (tabela de idiomas da própria API).
  static const Map<String, int> idsIdioma = {'pt': 7, 'en': 2};

  /// Quantidade máxima de resultados por busca.
  static const int limiteResultados = 20;

  /// Mínimo de letras para disparar a busca.
  static const int minimoCaracteres = 3;

  /// Tempo máximo de espera por uma resposta do wger.
  static const Duration timeout = Duration(seconds: 12);
}
