import 'package:flutter/material.dart';
import '../services/workout_store.dart';
import '../widgets/responsive_container.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workouts = WorkoutStore.workouts;

    // Agrupa as cargas registradas por nome de exercício, em ordem cronológica
    final Map<String, List<double>> cargasPorExercicio = {};
    for (final workout in workouts) {
      for (final exercicio in workout.exercicios) {
        cargasPorExercicio.putIfAbsent(exercicio.nome, () => []);
        cargasPorExercicio[exercicio.nome]!.add(exercicio.carga);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Progresso')),
      body: cargasPorExercicio.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Ainda não há dados suficientes.\nRegistre treinos para ver sua evolução aqui!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          : ResponsiveContainer(
              maxWidth: 900,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Telas largas: 2 colunas. Telas estreitas: 1 coluna.
                  final isWide = constraints.maxWidth > 500;

                  return GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 2 : 1,
                      mainAxisExtent: 230, // altura fixa e com folga, evita overflow
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: cargasPorExercicio.length,
                    itemBuilder: (context, index) {
                      final nome = cargasPorExercicio.keys.elementAt(index);
                      final cargas = cargasPorExercicio[nome]!;
                      final maiorCarga = cargas.reduce((a, b) => a > b ? a : b);
                      // Altura só da barra (a parte azul)
                      const alturaMaxBarra = 60.0;
                      // Altura total da área do gráfico: barra + espaço + número embaixo
                      const alturaAreaGrafico = 84.0;

                      return Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                nome,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Maior carga registrada: ${maiorCarga.toStringAsFixed(1)} kg',
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              // "Gráfico" simples feito com barras nativas,
                              // sem depender de bibliotecas externas.
                              SizedBox(
                                height: alturaAreaGrafico, // reserva espaço pra barra + número
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: cargas.map((carga) {
                                    final altura = maiorCarga > 0
                                        ? (carga / maiorCarga) * alturaMaxBarra
                                        : 0.0;
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 3),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              height: altura.clamp(4.0, alturaMaxBarra),
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              carga.toStringAsFixed(0),
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}