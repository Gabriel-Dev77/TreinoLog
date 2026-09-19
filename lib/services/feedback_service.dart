import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class FeedbackService {
  static void success(BuildContext context, String mensagem) {
    HapticFeedback.lightImpact(); // feedback tátil
    _show(context, mensagem, Icons.check_circle, AppTheme.success);
  }

  static void error(BuildContext context, String mensagem) {
    HapticFeedback.heavyImpact(); // vibração mais forte = erro
    _show(context, mensagem, Icons.error, AppTheme.error);
  }

  static void info(BuildContext context, String mensagem) {
    HapticFeedback.selectionClick();
    _show(context, mensagem, Icons.info, AppTheme.primaryDark);
  }

  static void _show(
    BuildContext context,
    String mensagem,
    IconData icone,
    Color cor,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar(); // evita empilhar mensagens

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: cor,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            // O ícone é redundante à cor (acessibilidade para daltonismo),
            // mas não deve ser lido pelo leitor de tela, pois a mensagem
            // de texto ao lado já comunica tudo.
            ExcludeSemantics(child: Icon(icone, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}