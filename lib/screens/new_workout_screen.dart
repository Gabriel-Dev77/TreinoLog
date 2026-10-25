import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/api_service.dart';
import '../services/feedback_service.dart';
import '../services/workout_store.dart';
import '../utils/validators.dart';
import '../widgets/exercise_tile.dart';
import '../widgets/offline_banner.dart';
import '../widgets/responsive_container.dart';

class NewWorkoutScreen extends StatefulWidget {
  const NewWorkoutScreen({super.key});

  @override
  State<NewWorkoutScreen> createState() => _NewWorkoutScreenState();
}

class _NewWorkoutScreenState extends State<NewWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _seriesController = TextEditingController();
  final _repeticoesController = TextEditingController();
  final _cargaController = TextEditingController();

  final List<Exercise> _exercicios = [];
  bool _salvando = false;

  void _adicionarExercicio() {
    // Valida todos os campos; os erros aparecem embaixo de cada um.
    if (!_formKey.currentState!.validate()) {
      FeedbackService.error(context, 'Corrija os campos destacados em vermelho');
      return;
    }

    final exercicio = Exercise(
      id: WorkoutStore.generateId(), // id temporário; o servidor gera o definitivo
      nome: _nomeController.text.trim(),
      series: Validators.parseInteiro(_seriesController.text),
      repeticoes: Validators.parseInteiro(_repeticoesController.text),
      carga: Validators.parseCarga(_cargaController.text),
    );

    setState(() {
      _exercicios.add(exercicio);
      _nomeController.clear();
      _seriesController.clear();
      _repeticoesController.clear();
      _cargaController.clear();
    });

    FeedbackService.info(context, '"${exercicio.nome}" adicionado ao treino');
  }

  void _removerExercicio(Exercise exercicio) {
    setState(() => _exercicios.removeWhere((e) => e.id == exercicio.id));
    FeedbackService.info(context, '"${exercicio.nome}" removido do treino');
  }

  Future<void> _salvarTreino() async {
    if (_exercicios.isEmpty) {
      FeedbackService.error(context, 'Adicione pelo menos um exercício antes de salvar');
      return;
    }

    setState(() => _salvando = true);

    final treino = Workout(
      id: WorkoutStore.generateId(),
      data: DateTime.now(),
      exercicios: List.from(_exercicios),
    );

    try {
      await WorkoutStore.addWorkout(treino);
      if (!mounted) return;
      setState(() => _exercicios.clear());
      FeedbackService.success(context, 'Treino salvo com sucesso! Veja no Histórico.');
    } on ApiException catch (e) {
      // Os exercícios continuam na tela, para o usuário tentar de novo.
      if (mounted) FeedbackService.error(context, e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _seriesController.dispose();
    _repeticoesController.dispose();
    _cargaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Treino')),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ResponsiveContainer(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Adicionar exercício',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _nomeController,
                        maxLength: Validators.nomeMax,
                        textCapitalization: TextCapitalization.sentences,
                        validator: Validators.nome,
                        decoration: const InputDecoration(
                          labelText: 'Nome do exercício',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 4),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 400;

                          final campos = [
                            TextFormField(
                              controller: _seriesController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: Validators.series,
                              decoration: const InputDecoration(
                                labelText: 'Séries',
                                border: OutlineInputBorder(),
                                errorMaxLines: 2,
                              ),
                            ),
                            TextFormField(
                              controller: _repeticoesController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: Validators.repeticoes,
                              decoration: const InputDecoration(
                                labelText: 'Repetições',
                                border: OutlineInputBorder(),
                                errorMaxLines: 2,
                              ),
                            ),
                            TextFormField(
                              controller: _cargaController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
                              ],
                              validator: Validators.carga,
                              decoration: const InputDecoration(
                                labelText: 'Carga (kg)',
                                border: OutlineInputBorder(),
                                errorMaxLines: 2,
                              ),
                            ),
                          ];

                          if (isNarrow) {
                            return Column(
                              children: campos
                                  .map((c) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: c,
                                      ))
                                  .toList(),
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: campos
                                .map((c) => Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: c,
                                      ),
                                    ))
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _salvando ? null : _adicionarExercicio,
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar exercício'),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 8),

                      Text(
                        'Exercícios do treino (${_exercicios.length})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      if (_exercicios.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('Nenhum exercício adicionado ainda.'),
                        ),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _exercicios.length,
                        itemBuilder: (context, index) {
                          final exercicio = _exercicios[index];
                          return ExerciseTile(
                            exercise: exercicio,
                            onRemove: _salvando ? null : () => _removerExercicio(exercicio),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _salvando ? null : _salvarTreino,
                          icon: _salvando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(_salvando ? 'Enviando ao servidor...' : 'Salvar treino'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
