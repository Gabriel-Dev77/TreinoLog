import 'package:flutter/material.dart';
import '../models/exercise.dart';

// Esse widget é REUTILIZÁVEL: vai aparecer aqui na tela de Novo Treino
// e depois também na tela de Histórico, sem duplicar código.
class ExerciseTile extends StatelessWidget {
  final Exercise exercise;

  const ExerciseTile({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.fitness_center),
        title: Text(exercise.nome),
        subtitle: Text(
          '${exercise.series} séries x ${exercise.repeticoes} repetições — ${exercise.carga} kg',
        ),
      ),
    );
  }
}