import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/hydration_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/workout_provider.dart';
import '../services/feedback_service.dart';
import '../widgets/responsive_container.dart';

/// Tela Perfil: configurações que valem para o app inteiro.
///
/// Etapa 7: tudo que é alterado aqui fica no estado global e aparece na
/// hora nas outras telas (ex: mudar a meta de água atualiza a Início e
/// reagenda os lembretes). Também é aqui que o recurso nativo de
/// notificações é ligado, com o pedido de permissão.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nome;
  bool _processandoLembretes = false;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: context.read<SettingsProvider>().nome);
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _salvarNome() async {
    FocusScope.of(context).unfocus();
    await context.read<SettingsProvider>().definirNome(_nome.text);
    if (mounted) FeedbackService.success(context, 'Nome atualizado');
  }

  Future<void> _alterarLembretes(bool ligar) async {
    final agua = context.read<HydrationProvider>();
    setState(() => _processandoLembretes = true);

    if (!ligar) {
      await agua.desativarLembretes();
      if (mounted) {
        setState(() => _processandoLembretes = false);
        FeedbackService.info(context, 'Lembretes de água desligados');
      }
      return;
    }

    final status = await agua.ativarLembretes();
    if (!mounted) return;
    setState(() => _processandoLembretes = false);
    _mostrarResultado(status, sucesso: 'Lembretes ligados! Você será lembrado ao longo do dia.');
  }

  Future<void> _enviarTeste() async {
    final status = await context.read<HydrationProvider>().enviarTeste();
    if (!mounted) return;
    _mostrarResultado(status, sucesso: 'Notificação de teste enviada. Confira a barra de notificações.');
  }

  void _mostrarResultado(StatusLembretes status, {required String sucesso}) {
    switch (status) {
      case StatusLembretes.ativos:
        FeedbackService.success(context, sucesso);
      case StatusLembretes.permissaoNegada:
        FeedbackService.error(
          context,
          'Permissão de notificações negada. Toque em "Abrir configurações" para permitir.',
        );
      case StatusLembretes.indisponivel:
        FeedbackService.error(context, 'Notificações não estão disponíveis neste dispositivo.');
      case StatusLembretes.erro:
        FeedbackService.error(context, 'Não foi possível usar as notificações. Tente novamente.');
      case StatusLembretes.desativados:
        break;
    }
  }

  Future<void> _abrirConfiguracoes() async {
    final abriu = await context.read<HydrationProvider>().abrirConfiguracoesDoSistema();
    if (!abriu && mounted) {
      FeedbackService.error(
        context,
        'Não foi possível abrir as configurações. Vá em Configurações > Apps > TreinoLog > Notificações.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<SettingsProvider>();
    final agua = context.watch<HydrationProvider>();
    final totalTreinos = context.watch<WorkoutProvider>().workouts.length;
    final titulo = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Identificação ------------------------------------------------
              Row(
                children: [
                  const ExcludeSemantics(
                    child: CircleAvatar(radius: 32, child: Icon(Icons.person, size: 32)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(config.nomeExibicao,
                            style: Theme.of(context).textTheme.headlineSmall),
                        Text('$totalTreinos treino(s) registrado(s)'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nome,
                maxLength: 30,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _salvarNome(),
                decoration: InputDecoration(
                  labelText: 'Seu nome',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check),
                    tooltip: 'Salvar nome',
                    onPressed: _salvarNome,
                  ),
                ),
              ),

              const Divider(height: 32),

              // --- Meta de água (estado global) ---------------------------------
              Text('Hidratação', style: titulo),
              const SizedBox(height: 8),
              Row(
                children: [
                  const ExcludeSemantics(child: Icon(Icons.water_drop, color: Colors.lightBlue)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text('Meta diária: ${config.metaAgua} copos'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Diminuir meta',
                    onPressed: config.metaAgua <= SettingsProvider.metaMinima
                        ? null
                        : () => config.definirMetaAgua(config.metaAgua - 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Aumentar meta',
                    onPressed: config.metaAgua >= SettingsProvider.metaMaxima
                        ? null
                        : () => config.definirMetaAgua(config.metaAgua + 1),
                  ),
                ],
              ),
              Text(
                'Hoje: ${agua.copos} de ${agua.meta} copos',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const Divider(height: 32),

              // --- Lembretes (recurso nativo: notificações) --------------------
              Text('Lembretes de água', style: titulo),
              _buildLembretes(context, config, agua),

              const Divider(height: 32),

              Text('Sobre o aplicativo', style: titulo),
              const SizedBox(height: 8),
              const Text(
                'O TreinoLog ajuda você a registrar treinos de musculação e '
                'acompanhar sua hidratação diária, sem complicação.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLembretes(BuildContext context, SettingsProvider config, HydrationProvider agua) {
    final status = agua.statusLembretes;

    // Recurso inexistente (ex: navegador): mostra o motivo e desabilita tudo.
    if (!agua.lembretesSuportados) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.notifications_off),
        title: Text('Indisponível neste dispositivo'),
        subtitle: Text(
          'Os lembretes usam as notificações do Android. Abra o app no celular para usá-los; '
          'o restante do app funciona normalmente aqui.',
        ),
      );
    }

    final ativos = config.lembretesAtivos;
    final proximo = agua.proximoLembrete;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(ativos ? Icons.notifications_active : Icons.notifications_none),
          title: const Text('Lembrar de beber água'),
          subtitle: Text(
            'A cada ${config.intervaloHoras}h, das ${SettingsProvider.horaInicioLembretes}h às '
            '${SettingsProvider.horaFimLembretes}h. Param quando a meta do dia é atingida.',
          ),
          value: ativos,
          onChanged: _processandoLembretes ? null : _alterarLembretes,
        ),
        Row(
          children: [
            const Text('Intervalo:'),
            const SizedBox(width: 12),
            DropdownButton<int>(
              value: config.intervaloHoras,
              onChanged: ativos ? (h) => config.definirIntervaloHoras(h!) : null,
              items: SettingsProvider.intervalosDisponiveis
                  .map((h) => DropdownMenuItem(value: h, child: Text('a cada ${h}h')))
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (status == StatusLembretes.ativos)
          Text(
            proximo == null
                ? 'Nenhum lembrete pendente.'
                : 'Próximo lembrete: ${proximo.day.toString().padLeft(2, '0')}/'
                    '${proximo.month.toString().padLeft(2, '0')} às '
                    '${proximo.hour.toString().padLeft(2, '0')}:00',
            style: Theme.of(context).textTheme.bodySmall,
          ),

        // Permissão negada: explica e leva às configurações do sistema.
        if (status == StatusLembretes.permissaoNegada)
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'O TreinoLog não tem permissão para mostrar notificações, '
                    'então os lembretes não podem ser enviados.',
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _abrirConfiguracoes,
                    icon: const Icon(Icons.settings),
                    label: const Text('Abrir configurações'),
                  ),
                ],
              ),
            ),
          ),

        if (status == StatusLembretes.erro)
          Text(
            'Não foi possível agendar os lembretes. Tente desligar e ligar novamente.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),

        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _enviarTeste,
          icon: const Icon(Icons.notifications),
          label: const Text('Enviar lembrete de teste'),
        ),
      ],
    );
  }
}
