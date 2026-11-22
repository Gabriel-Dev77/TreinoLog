import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/workout.dart';

/// Resultado do compartilhamento, já pensado para o feedback da tela.
enum ResultadoCompartilhamento {
  /// O usuário escolheu um app e compartilhou.
  compartilhado,

  /// A janela de compartilhamento abriu, mas o usuário fechou sem escolher.
  cancelado,

  /// O sistema não informa o resultado (comum em alguns Androids e no navegador).
  enviado,

  /// Não foi possível abrir o compartilhamento; o texto foi copiado.
  copiadoParaAreaDeTransferencia,

  /// Nem o compartilhamento nem a cópia funcionaram.
  falhou,
}

/// RECURSO NATIVO (extra): janela de compartilhamento do sistema,
/// via pacote `share_plus`. Não exige permissão.
class ShareService {
  /// Monta o texto do treino que será compartilhado (WhatsApp, e-mail...).
  static String textoDoTreino(Workout treino) {
    final d = treino.data;
    String dois(int n) => n.toString().padLeft(2, '0');

    String numero(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

    final volume = treino.exercicios.fold<double>(
      0,
      (soma, e) => soma + e.series * e.repeticoes * e.carga,
    );

    final linhas = <String>[
      '🏋️ Meu treino de ${dois(d.day)}/${dois(d.month)}/${d.year} às ${dois(d.hour)}:${dois(d.minute)}',
      '',
      for (final e in treino.exercicios)
        '• ${e.nome}: ${e.series}x${e.repeticoes}'
            '${e.carga > 0 ? ' com ${numero(e.carga)} kg' : ' (peso corporal)'}',
      '',
      '${treino.exercicios.length} exercício(s) · volume total: ${numero(volume)} kg',
      'Registrado com o TreinoLog',
    ];
    return linhas.join('\n');
  }

  /// Abre a janela de compartilhamento do sistema com o resumo do treino.
  /// Se o recurso falhar ou não existir, copia o texto para a área de
  /// transferência, para o usuário colar onde quiser.
  static Future<ResultadoCompartilhamento> compartilharTreino(Workout treino) async {
    final texto = textoDoTreino(treino);
    try {
      final resultado = await SharePlus.instance.share(
        ShareParams(text: texto, subject: 'Meu treino no TreinoLog'),
      );
      return switch (resultado.status) {
        ShareResultStatus.success => ResultadoCompartilhamento.compartilhado,
        ShareResultStatus.dismissed => ResultadoCompartilhamento.cancelado,
        ShareResultStatus.unavailable => ResultadoCompartilhamento.enviado,
      };
    } catch (_) {
      try {
        await Clipboard.setData(ClipboardData(text: texto));
        return ResultadoCompartilhamento.copiadoParaAreaDeTransferencia;
      } catch (_) {
        return ResultadoCompartilhamento.falhou;
      }
    }
  }
}
