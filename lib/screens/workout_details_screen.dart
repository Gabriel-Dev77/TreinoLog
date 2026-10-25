import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/api_service.dart';
import '../services/feedback_service.dart';
import '../services/workout_store.dart';
import '../utils/validators.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/offline_banner.dart';

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
      await WorkoutStore.updateExercise(workout.id, editado);
      if (mounted) FeedbackService.success(context, 'Exercício atualizado');
    } on ApiException catch (e) {
      if (mounted) FeedbackService.error(context, e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  /// EXCLUIR: apaga o treino inteiro e volta para o Histórico.
  Future<void> _excluirTreino(Workout workout) async {
    if (!await confirmarExclusaoDeTreino(context)) return;
    if (!mounted) return;

    setState(() => _salvando = true);
    try {
      await WorkoutStore.removeWorkout(workout);
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
    return ValueListenableBuilder<int>(
      valueListenable: WorkoutStore.changes,
      builder: (context, _, _) {
        final workout = WorkoutStore.findById(widget.workoutId);

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
                                leading: const Icon(Icons.fitness_center),
                                title: Text(exercicio.nome),
                                subtitle: Text(
                                  '${exercicio.series} séries x ${exercicio.repeticoes} repetições — '
                                  '${exercicio.carga.toStringAsFixed(1)} kg',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Editar exercício',
                                  onPressed: _salvando
                                      ? null
                                      : () => _editarExercicio(workout, exercicio),
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

  @override
  void initState() {
    super.initState();
    final e = widget.exercicio;
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
      ),
    );
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
                decoration: const InputDecoration(labelText: 'Nome'),
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
