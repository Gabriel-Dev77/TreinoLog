import 'package:flutter/material.dart';
import '../widgets/responsive_container.dart';
import '../services/feedback_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _coposDeAgua = 0;
  final int _metaDeAgua = 8;

  void _adicionarCopo() {
    setState(() {
      if (_coposDeAgua < _metaDeAgua) {
        _coposDeAgua++;
      }
    });

    if (_coposDeAgua >= _metaDeAgua) {
      FeedbackService.success(context, 'Meta de hidratação atingida! 💧');
    } else {
      FeedbackService.info(context, 'Copo registrado ($_coposDeAgua/$_metaDeAgua)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TreinoLog'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumo de hoje', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MergeSemantics(
                    child: Row(
                      children: [
                        const ExcludeSemantics(
                          child: Icon(Icons.fitness_center, size: 32, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Nenhum treino registrado hoje',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // liveRegion: true faz o leitor de tela anunciar
                      // automaticamente quando o valor muda, sem precisar
                      // que o usuário navegue até o texto de novo.
                      Semantics(
                        liveRegion: true,
                        label: 'Hidratação: $_coposDeAgua de $_metaDeAgua copos',
                        child: ExcludeSemantics(
                          child: Row(
                            children: [
                              const Icon(Icons.water_drop, size: 32, color: Colors.lightBlue),
                              const SizedBox(width: 12),
                              Text(
                                'Hidratação: $_coposDeAgua / $_metaDeAgua copos',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: Semantics(
                          label: 'Registrar copo de água',
                          hint: 'Adiciona um copo ao contador de hidratação do dia',
                          button: true,
                          child: ElevatedButton.icon(
                            onPressed: _coposDeAgua >= _metaDeAgua ? null : _adicionarCopo,
                            icon: const Icon(Icons.add),
                            label: const Text('Registrar copo de água'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}