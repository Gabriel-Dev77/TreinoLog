import 'package:flutter/material.dart';
import 'profile_screen.dart';
import '../widgets/responsive_container.dart';

// Agora é Stateful, porque o contador de água MUDA
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variáveis que guardam o estado da tela
  int _coposDeAgua = 0;
  final int _metaDeAgua = 8; // meta diária, por exemplo 8 copos

  void _adicionarCopo() {
    setState(() {
      if (_coposDeAgua < _metaDeAgua) {
        _coposDeAgua++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TreinoLog'),
        actions: [
          // Botão de perfil no canto superior direito
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Navigator.push abre uma nova tela "por cima" da atual
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        // SingleChildScrollView permite rolar a tela se o conteúdo não couber
        padding: const EdgeInsets.all(16.0),
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumo de hoje',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16), // espaçamento vertical

              // Card de treino do dia
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center, size: 32, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Nenhum treino registrado hoje',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card de hidratação
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.water_drop, size: 32, color: Colors.lightBlue),
                          const SizedBox(width: 12),
                          Text(
                            'Hidratação: $_coposDeAgua / $_metaDeAgua copos',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _adicionarCopo,
                        icon: const Icon(Icons.add),
                        label: const Text('Registrar copo de água'),
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