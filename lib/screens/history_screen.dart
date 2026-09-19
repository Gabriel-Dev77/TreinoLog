import 'package:flutter/material.dart';
import '../services/workout_store.dart';
import '../services/feedback_service.dart';
import '../widgets/exercise_tile.dart';
import '../widgets/responsive_container.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    // Simula um breve carregamento para demonstrar o Skeleton Screen:
    // a estrutura da tela aparece antes dos dados, reduzindo a
    // percepção de demora (conforme a aula de UX).
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _carregando = false);
    });
  }

  Future<void> _confirmarExclusao(workout) async {
    // Ação destrutiva: exige confirmação explícita, aumentando o
    // "atrito" de propósito (Lei de Fitts para ações destrutivas).
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir treino?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          Semantics(
            label: 'Confirmar exclusão do treino',
            button: true,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir'),
            ),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      setState(() {
        WorkoutStore.removeWorkout(workout);
      });
      if (mounted) FeedbackService.success(context, 'Treino excluído');
    }
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} às '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final workouts = WorkoutStore.workouts;

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Treinos')),
      body: _carregando
          ? _buildSkeleton()
          : workouts.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Nenhum treino registrado ainda.\nVá até "Novo Treino" para começar!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              : ResponsiveContainer(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    reverse: true,
                    itemCount: workouts.length,
                    itemBuilder: (context, index) {
                      final workout = workouts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatarData(workout.data),
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Semantics(
                                    label: 'Excluir treino de ${_formatarData(workout.data)}',
                                    button: true,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _confirmarExclusao(workout),
                                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...workout.exercicios.map(
                                (exercicio) => ExerciseTile(exercise: exercicio),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}