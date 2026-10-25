import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/feedback_service.dart';
import '../services/workout_store.dart';

/// Faixa exibida no topo das telas quando o servidor não responde.
/// Some sozinha assim que a conexão volta.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _tentando = false;

  Future<void> _tentarNovamente() async {
    setState(() => _tentando = true);
    try {
      await WorkoutStore.refresh();
      if (mounted) FeedbackService.success(context, 'Conexão com o servidor restabelecida');
    } on ApiException catch (e) {
      if (mounted) FeedbackService.error(context, e.mensagem);
    } finally {
      if (mounted) setState(() => _tentando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: WorkoutStore.offline,
      builder: (context, offline, _) {
        if (!offline) return const SizedBox.shrink();

        return Semantics(
          liveRegion: true,
          child: Container(
            width: double.infinity,
            color: Colors.orange.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const ExcludeSemantics(
                  child: Icon(Icons.cloud_off, color: Colors.deepOrange),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Sem conexão com o servidor. Mostrando os dados salvos no aparelho; '
                    'não é possível salvar alterações agora.',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
                TextButton(
                  onPressed: _tentando ? null : _tentarNovamente,
                  child: Text(_tentando ? 'Tentando...' : 'Tentar de novo'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
