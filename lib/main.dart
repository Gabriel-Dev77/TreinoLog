import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/new_workout_screen.dart';
import 'screens/history_screen.dart';
import 'screens/progress_screen.dart';

void main() {
  runApp(const TreinoLogApp());
}

// Widget raiz do app - configura tema, título, etc.
class TreinoLogApp extends StatelessWidget {
  const TreinoLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TreinoLog',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

// Esse widget PRECISA ser Stateful, porque a aba selecionada MUDA quando o usuário clica
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Guarda qual aba está selecionada agora (começa na 0 = Início)
  int _selectedIndex = 0;

  // Função chamada quando o usuário toca em um ícone do menu
  void _onItemTapped(int index) {
    setState(() {
      // setState avisa o Flutter: "algo mudou, redesenhe a tela"
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // A lista é criada AQUI DENTRO do build(), toda vez que ele roda.
    // HistoryScreen e ProgressScreen ficam sem "const" de propósito:
    // assim, cada vez que o build() executar de novo (ex: ao trocar de
    // aba), uma nova instância delas é criada, e o Flutter é forçado a
    // redesenhar com os dados mais atuais do WorkoutStore, em vez de
    // reaproveitar uma versão antiga "congelada".
    final List<Widget> screens = [
      const HomeScreen(),
      const NewWorkoutScreen(),
      HistoryScreen(),
      ProgressScreen(),
    ];

    return Scaffold(
      // IndexedStack mantém o estado de cada tela mesmo trocando de aba
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Novo Treino',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progresso',
          ),
        ],
      ),
    );
  }
}