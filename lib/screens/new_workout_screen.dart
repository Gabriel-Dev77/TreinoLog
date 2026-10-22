import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/workout_store.dart';
import '../widgets/exercise_tile.dart';
import '../widgets/responsive_container.dart';

class NewWorkoutScreen extends StatefulWidget {
  const NewWorkoutScreen({super.key});

  @override
  State<NewWorkoutScreen> createState() => _NewWorkoutScreenState();
}

class _NewWorkoutScreenState extends State<NewWorkoutScreen> {
  final _nomeController = TextEditingController();
  final _seriesController = TextEditingController();
  final _repeticoesController = TextEditingController();
  final _cargaController = TextEditingController();

  final List<Exercise> _exercicios = [];
  bool _salvando = false;

  void _adicionarExercicio() {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o nome do exercício')),
      );
      return;
    }

    final exercicio = Exercise(
      id: WorkoutStore.generateId(),
      nome: _nomeController.text.trim(),
      series: int.tryParse(_seriesController.text) ?? 0,
      repeticoes: int.tryParse(_repeticoesController.text) ?? 0,
      carga: double.tryParse(_cargaController.text) ?? 0,
    );

    setState(() {
      _exercicios.add(exercicio);
      _nomeController.clear();
      _seriesController.clear();
      _repeticoesController.clear();
      _cargaController.clear();
    });
  }

  // Agora é assíncrona: grava no disco antes de limpar a tela.
  Future<void> _salvarTreino() async {
    if (_exercicios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um exercício')),
      );
      return;
    }

    setState(() => _salvando = true);

    final treino = Workout(
      id: WorkoutStore.generateId(),
      data: DateTime.now(),
      exercicios: List.from(_exercicios),
    );

    await WorkoutStore.addWorkout(treino);

    if (!mounted) return;

    setState(() {
      _exercicios.clear();
      _salvando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Treino salvo com sucesso!')),
    );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adicionar exercício',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do exercício',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 400;

                  final campos = [
                    TextField(
                      controller: _seriesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Séries',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextField(
                      controller: _repeticoesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Repetições',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextField(
                      controller: _cargaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Carga (kg)',
                        border: OutlineInputBorder(),
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
                  onPressed: _adicionarExercicio,
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
                  return ExerciseTile(exercise: _exercicios[index]);
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
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(_salvando ? 'Salvando...' : 'Salvar treino'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}