import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/new_workout_screen.dart';
import 'screens/history_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'services/workout_store.dart';
import 'theme/app_theme.dart';

void main() async {
  // Necessário antes de usar qualquer plugin nativo (como SharedPreferences)
  // fora do runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega o cache local ANTES do app abrir (a primeira tela já mostra
  // os treinos conhecidos) e dispara, em segundo plano, a sincronização
  // com o backend. Se o servidor estiver fora do ar, o app abre mesmo assim.
  await WorkoutStore.init();

  runApp(const TreinoLogApp());
}

class TreinoLogApp extends StatelessWidget {
  const TreinoLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TreinoLog',
      theme: AppTheme.build(),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static const _abas = [
    ('Início', Icons.home, 'Resumo do dia e hidratação'),
    ('Novo Treino', Icons.add_circle_outline, 'Registrar um novo treino'),
    ('Histórico', Icons.history, 'Ver treinos já registrados'),
    ('Progresso', Icons.show_chart, 'Ver evolução de carga por exercício'),
    ('Perfil', Icons.person, 'Ver informações do perfil'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      const NewWorkoutScreen(),
      HistoryScreen(),
      ProgressScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: _abas.map((aba) {
          final (label, icon, hint) = aba;
          return BottomNavigationBarItem(
            icon: Semantics(
              label: label,
              hint: hint,
              button: true,
              child: Icon(icon),
            ),
            label: label,
          );
        }).toList(),
      ),
    );
  }
}