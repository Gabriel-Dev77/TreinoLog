/// Regras de validação dos campos de exercício.
/// Os mesmos limites são conferidos no backend (backend/src/validation.js).
class Validators {
  static const int nomeMax = 60;
  static const int seriesMin = 1;
  static const int seriesMax = 50;
  static const int repeticoesMin = 1;
  static const int repeticoesMax = 500;
  static const double cargaMin = 0;
  static const double cargaMax = 1000;

  static String? nome(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe o nome do exercício';
    if (texto.length > nomeMax) return 'Use no máximo $nomeMax caracteres';
    return null;
  }

  static String? series(String? valor) =>
      _inteiro(valor, 'séries', seriesMin, seriesMax);

  static String? repeticoes(String? valor) =>
      _inteiro(valor, 'repetições', repeticoesMin, repeticoesMax);

  static String? carga(String? valor) {
    final texto = _normalizarDecimal(valor);
    if (texto.isEmpty) return 'Informe a carga (0 para peso corporal)';
    final numero = double.tryParse(texto);
    if (numero == null) return 'Carga inválida';
    if (numero < cargaMin || numero > cargaMax) {
      return 'A carga deve ficar entre ${cargaMin.toInt()} e ${cargaMax.toInt()} kg';
    }
    return null;
  }

  /// Converte o texto já validado em número (aceita vírgula ou ponto).
  static double parseCarga(String valor) => double.parse(_normalizarDecimal(valor));

  static int parseInteiro(String valor) => int.parse(valor.trim());

  static String? _inteiro(String? valor, String campo, int min, int max) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe as $campo';
    final numero = int.tryParse(texto);
    if (numero == null) return 'Valor inválido';
    if (numero < min || numero > max) return 'As $campo devem ficar entre $min e $max';
    return null;
  }

  static String _normalizarDecimal(String? valor) =>
      (valor ?? '').trim().replaceAll(',', '.');
}
