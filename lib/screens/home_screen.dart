import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/hydration_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/workout_provider.dart';
import '../services/feedback_service.dart';
import '../widgets/offline_banner.dart';
import '../widgets/responsive_container.dart';
import 'exercise_catalog_screen.dart';

/// Tela Início: resumo do dia.
///
/// Etapa 7: não guarda mais estado próprio. Lê três estados globais:
/// - [SettingsProvider]: nome do usuário (definido no Perfil);
/// - [WorkoutProvider]: treinos de hoje;
/// - [HydrationProvider]: copos de água, meta (definida no Perfil) e lembretes.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _adicionarCopo(BuildContext context) async {
    final agua = context.read<HydrationProvider>();
    await agua.adicionarCopo();
    if (!context.mounted) return;

    if (agua.metaAtingida) {
      FeedbackService.success(context, 'Meta de hidratação atingida! 💧 Lembretes pausados até amanhã.');
    } else {
      FeedbackService.info(context, 'Copo registrado (${agua.copos}/${agua.meta})');
    }
  }

  Future<void> _removerCopo(BuildContext context) async {
    final agua = context.read<HydrationProvider>();
    await agua.removerCopo();
    if (context.mounted) {
      FeedbackService.info(context, 'Último copo desfeito (${agua.copos}/${agua.meta})');
    }
  }

  String _textoLembretes(HydrationProvider agua) {
    switch (agua.statusLembretes) {
      case StatusLembretes.ativos:
        final proximo = agua.proximoLembrete;
        if (proximo == null) return 'Lembretes ativos.';
        final hoje = DateTime.now();
        final ehHoje = proximo.year == hoje.year &&
            proximo.month == hoje.month &&
            proximo.day == hoje.day;
        return 'Próximo lembrete: ${ehHoje ? 'hoje' : 'amanhã'} às '
            '${proximo.hour.toString().padLeft(2, '0')}:00';
      case StatusLembretes.desativados:
        return 'Lembretes desligados. Ative na aba Perfil.';
      case StatusLembretes.permissaoNegada:
        return 'Lembretes bloqueados: permita notificações na aba Perfil.';
      case StatusLembretes.indisponivel:
        return 'Lembretes não disponíveis neste dispositivo.';
      case StatusLembretes.erro:
        return 'Não foi possível agendar os lembretes.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('TreinoLog')),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ResponsiveContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, ${config.nomeExibicao}!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text('Resumo de hoje', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    const _CardTreinosDeHoje(),
                    const SizedBox(height: 16),
                    _buildCardAgua(context),
                    const SizedBox(height: 16),

                    // Etapa 6: acesso ao catálogo externo de exercícios (wger).
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const ExcludeSemantics(
                          child: Icon(Icons.menu_book, size: 32, color: Colors.blue),
                        ),
                        title: const Text('Catálogo de exercícios'),
                        subtitle: const Text('Pesquise exercícios, músculos trabalhados e como executar'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ExerciseCatalogScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardAgua(BuildContext context) {
    // watch: a tela é redesenhada quando o contador ou a meta mudam.
    final agua = context.watch<HydrationProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // liveRegion: o leitor de tela anuncia sozinho quando o valor muda.
            Semantics(
              liveRegion: true,
              label: 'Hidratação: ${agua.copos} de ${agua.meta} copos',
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    const Icon(Icons.water_drop, size: 32, color: Colors.lightBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hidratação: ${agua.copos} / ${agua.meta} copos',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    if (agua.metaAtingida)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: agua.progresso, minHeight: 10),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Registrar copo de água',
                    hint: 'Adiciona um copo ao contador de hidratação do dia',
                    button: true,
                    child: ElevatedButton.icon(
                      onPressed: agua.metaAtingida ? null : () => _adicionarCopo(context),
                      icon: const Icon(Icons.add),
                      label: Text(agua.metaAtingida ? 'Meta atingida' : 'Registrar copo de água'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: 'Desfazer último copo',
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: agua.copos == 0 ? null : () => _removerCopo(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    agua.statusLembretes == StatusLembretes.ativos
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    size: 18,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _textoLembretes(agua),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card com os treinos de hoje. Widget separado para que só ele seja
/// redesenhado quando a lista de treinos mudar.
class _CardTreinosDeHoje extends StatelessWidget {
  const _CardTreinosDeHoje();

  @override
  Widget build(BuildContext context) {
    final treinosHoje = context.watch<WorkoutProvider>().treinosDoDia(DateTime.now());
    final exercicios = treinosHoje.fold<int>(0, (soma, t) => soma + t.exercicios.length);
    final texto = treinosHoje.isEmpty
        ? 'Nenhum treino registrado hoje'
        : '${treinosHoje.length} '
            '${treinosHoje.length == 1 ? 'treino registrado' : 'treinos registrados'} hoje '
            '($exercicios ${exercicios == 1 ? 'exercício' : 'exercícios'})';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: MergeSemantics(
          child: Row(
            children: [
              const ExcludeSemantics(
                child: Icon(Icons.fitness_center, size: 32, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(texto, style: Theme.of(context).textTheme.bodyLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
