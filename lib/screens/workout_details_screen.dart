import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/workout_store.dart';

class WorkoutDetailsScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailsScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {
  late Workout _workout;

  @override
  void initState() {
    super.initState();
    _workout = widget.workout;
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} às '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  // Abre um diálogo para EDITAR um exercício já salvo e persiste a mudança.
  Future<void> _editarExercicio(Exercise exercicio) async {
    final nomeController = TextEditingController(text: exercicio.nome);
    final seriesController = TextEditingController(text: exercicio.series.toString());
    final repeticoesController = TextEditingController(text: exercicio.repeticoes.toString());
    final cargaController = TextEditingController(text: exercicio.carga.toString());

    final salvou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar exercício'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: seriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Séries'),
              ),
              TextField(
                controller: repeticoesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Repetições'),
              ),
              TextField(
                controller: cargaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Carga (kg)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (salvou != true) return;

    final exercicioAtualizado = exercicio.copyWith(
      nome: nomeController.text.trim().isEmpty ? exercicio.nome : nomeController.text.trim(),
      series: int.tryParse(seriesController.text) ?? exercicio.series,
      repeticoes: int.tryParse(repeticoesController.text) ?? exercicio.repeticoes,
      carga: double.tryParse(cargaController.text) ?? exercicio.carga,
    );

    // UPDATE: persiste a alteração no armazenamento local.
    await WorkoutStore.updateExercise(_workout.id, exercicioAtualizado);

    if (!mounted) return;

    setState(() {
      _workout = WorkoutStore.workouts.firstWhere((w) => w.id == _workout.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exercício atualizado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Treino')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatarData(_workout.data),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '${_workout.exercicios.length} exercício(s) registrado(s). '
              'Toque em um exercício para editar.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _workout.exercicios.length,
                itemBuilder: (context, index) {
                  final exercicio = _workout.exercicios[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Text(exercicio.nome),
                      subtitle: Text(
                        '${exercicio.series} séries x ${exercicio.repeticoes} repetições — ${exercicio.carga} kg',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar exercício',
                        onPressed: () => _editarExercicio(exercicio),
                      ),
                      onTap: () => _editarExercicio(exercicio),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}