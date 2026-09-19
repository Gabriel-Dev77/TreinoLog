import 'package:flutter/material.dart';
import '../models/exercise.dart';

class ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback? onRemove;

  const ExerciseTile({super.key, required this.exercise, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Ícone puramente decorativo: silenciado para o leitor de tela.
              const ExcludeSemantics(
                child: Icon(Icons.fitness_center, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      exercise.nome,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exercise.series} séries de ${exercise.repeticoes} '
                      'repetições com ${exercise.carga.toStringAsFixed(1)} quilos',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 8), // 8dp de espaço inativo entre alvos
                Semantics(
                  label: 'Remover ${exercise.nome}',
                  hint: 'Remove este exercício da lista do treino',
                  button: true,
                  child: IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                    // Alvo de toque mínimo de 48x48, conforme Material Design
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    tooltip: 'Remover exercício',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}