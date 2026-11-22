import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/catalog_exercise.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/api_service.dart';
import '../services/feedback_service.dart';
import '../services/share_service.dart';
import '../providers/workout_provider.dart';
import '../utils/validators.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/offline_banner.dart';
import 'catalog_exercise_detail_screen.dart';
import 'exercise_catalog_screen.dart';

class WorkoutDetailsScreen extends StatefulWidget {
  final String workoutId;

  const WorkoutDetailsScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {
  bool _salvando = false;

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} às '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  /// ALTERAR: abre o formulário, valida e envia a edição para a API.
  Future<void> _editarExercicio(Workout workout, Exercise exercicio) async {
    final editado = await showDialog<Exercise>(
      context: context,
      builder: (context) => _EditarExercicioDialog(exercicio: exercicio),
    );
    if (editado == null || !mounted) return; // cancelou

    setState(() => _salvando = true);
    try {
      await context.read<WorkoutProvider>().updateExercise(workout.id, editado);
      if (mounted) FeedbackService.success(context, 'Exercício atualizado');
    } on ApiException catch (e) {
      if (mounted) FeedbackService.error(context, e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  /// COMPARTILHAR: abre a janela de compartilhamento do sistema
  /// (WhatsApp, e-mail, Telegram...) com o resumo do treino.
  Future<void> _compartilhar(Workout workout) async {
    final resultado = await ShareService.compartilharTreino(workout);
    if (!mounted) return;
    switch (resultado) {
      case ResultadoCompartilhamento.compartilhado:
        FeedbackService.success(context, 'Treino compartilhado!');
      case ResultadoCompartilhamento.cancelado:
        FeedbackService.info(context, 'Compartilhamento cancelado');
      case ResultadoCompartilhamento.enviado:
        break; // o sistema não informa o resultado; nada a dizer
      case ResultadoCompartilhamento.copiadoParaAreaDeTransferencia:
        FeedbackService.info(
          context,
          'Não foi possível abrir o compartilhamento. O resumo foi copiado: cole onde quiser.',
        );
      case ResultadoCompartilhamento.falhou:
        FeedbackService.error(context, 'Não foi possível compartilhar o treino neste dispositivo.');
    }
  }

  void _verNoCatalogo(int wgerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CatalogExerciseDetailScreen(exerciseId: wgerId),
      ),
    );
  }

  /// EXCLUIR: apaga o treino inteiro e volta para o Histórico.
  Future<void> _excluirTreino(Workout workout) async {
    if (!await confirmarExclusaoDeTreino(context)) return;
    if (!mounted) return;

    setState(() => _salvando = true);
    try {
      await context.read<WorkoutProvider>().removeWorkout(workout);
      if (!mounted) return;
      FeedbackService.success(context, 'Treino excluído');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      FeedbackService.error(context, e.mensagem);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Etapa 7: watch redesenha a tela quando o estado global de treinos muda.
    return Builder(
      builder: (context) {
        final workout = context.watch<WorkoutProvider>().findById(widget.workoutId);

        // O treino pode ter sido apagado (ex: lista atualizada do servidor).
        if (workout == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalhes do Treino')),
            body: const Center(child: Text('Este treino não existe mais.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalhes do Treino'),
            actions: [
              // Etapa 7: recurso nativo de compartilhamento.
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Compartilhar treino',
                onPressed: _salvando ? null : () => _compartilhar(workout),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Excluir treino',
                onPressed: _salvando ? null : () => _excluirTreino(workout),
              ),
            ],
          ),
          body: Column(
            children: [
              const OfflineBanner(),
              if (_salvando) const LinearProgressIndicator(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatarData(workout.data),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${workout.exercicios.length} exercício(s) registrado(s). '
                        'Toque em um exercício para editar.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: workout.exercicios.length,
                          itemBuilder: (context, index) {
                            final exercicio = workout.exercicios[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: Icon(
                                  exercicio.wgerId != null
                                      ? Icons.menu_book
                                      : Icons.fitness_center,
                                ),
                                title: Text(exercicio.nome),
                                subtitle: Text(
                                  '${exercicio.series} séries x ${exercicio.repeticoes} repetições — '
                                  '${exercicio.carga.toStringAsFixed(1)} kg',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Etapa 6: consulta o exercício no catálogo wger.
                                    if (exercicio.wgerId != null)
                                      IconButton(
                                        icon: const Icon(Icons.info_outline),
                                        tooltip: 'Ver ${exercicio.nome} no catálogo',
                                        onPressed: () => _verNoCatalogo(exercicio.wgerId!),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: 'Editar exercício',
                                      onPressed: _salvando
                                          ? null
                                          : () => _editarExercicio(workout, exercicio),
                                    ),
                                  ],
                                ),
                                onTap: _salvando
                                    ? null
                                    : () => _editarExercicio(workout, exercicio),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Formulário de edição de um exercício, com validação dos campos.
/// Devolve o exercício editado, ou null se o usuário cancelar.
class _EditarExercicioDialog extends StatefulWidget {
  final Exercise exercicio;

  const _EditarExercicioDialog({required this.exercicio});

  @override
  State<_EditarExercicioDialog> createState() => _EditarExercicioDialogState();
}

class _EditarExercicioDialogState extends State<_EditarExercicioDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _series;
  late final TextEditingController _repeticoes;
  late final TextEditingController _carga;

  /// Etapa 6: id no catálogo wger (null = sem vínculo) e nome para exibir no chip.
  int? _wgerId;
  String? _nomeCatalogo;

  @override
  void initState() {
    super.initState();
    final e = widget.exercicio;
    _wgerId = e.wgerId;
    _nome = TextEditingController(text: e.nome);
    _series = TextEditingController(text: e.series.toString());
    _repeticoes = TextEditingController(text: e.repeticoes.toString());
    _carga = TextEditingController(text: e.carga.toString());
  }

  @override
  void dispose() {
    _nome.dispose();
    _series.dispose();
    _repeticoes.dispose();
    _carga.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      widget.exercicio.copyWith(
        nome: _nome.text.trim(),
        series: Validators.parseInteiro(_series.text),
        repeticoes: Validators.parseInteiro(_repeticoes.text),
        carga: Validators.parseCarga(_carga.text),
        wgerId: _wgerId,
        removerWgerId: _wgerId == null,
      ),
    );
  }

  /// ATUALIZAÇÃO com dados externos: troca o exercício por um do catálogo.
  Future<void> _escolherDoCatalogo() async {
    final escolhido = await Navigator.push<CatalogExercise>(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseCatalogScreen(modoSelecao: true, termoInicial: _nome.text.trim()),
      ),
    );
    if (escolhido == null || !mounted) return;
    setState(() {
      _wgerId = escolhido.id;
      _nomeCatalogo = escolhido.nome;
      _nome.text = escolhido.nome;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar exercício'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nome,
                maxLength: Validators.nomeMax,
                validator: Validators.nome,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.manage_search),
                    tooltip: 'Escolher do catálogo de exercícios',
                    onPressed: _escolherDoCatalogo,
                  ),
                ),
              ),
              if (_wgerId != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    avatar: const Icon(Icons.menu_book, size: 18),
                    label: Text(
                      _nomeCatalogo != null
                          ? 'Catálogo: $_nomeCatalogo'
                          : 'Vinculado ao catálogo',
                    ),
                    deleteButtonTooltipMessage: 'Remover vínculo com o catálogo',
                    onDeleted: () => setState(() {
                      _wgerId = null;
                      _nomeCatalogo = null;
                    }),
                  ),
                ),
              TextFormField(
                controller: _series,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.series,
                decoration: const InputDecoration(labelText: 'Séries'),
              ),
              TextFormField(
                controller: _repeticoes,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.repeticoes,
                decoration: const InputDecoration(labelText: 'Repetições'),
              ),
              TextFormField(
                controller: _carga,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
                ],
                validator: Validators.carga,
                decoration: const InputDecoration(labelText: 'Carga (kg)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
