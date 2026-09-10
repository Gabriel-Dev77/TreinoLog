import 'package:flutter/material.dart';
import '../services/workout_store.dart';
import '../widgets/exercise_tile.dart';
import '../widgets/responsive_container.dart';

// Precisa ser Stateful porque, ao voltar pra essa tela depois de
// salvar um treino novo, ela precisa "atualizar" a lista mostrada.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final workouts = WorkoutStore.workouts;

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Treinos')),
      body: workouts.isEmpty
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
                // reverse: true faz o treino mais recente aparecer primeiro
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
                          Text(
                            _formatarData(workout.data),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Mapeia cada exercício do treino para um ExerciseTile
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

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} às '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }
}