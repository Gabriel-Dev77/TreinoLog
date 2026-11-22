import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/hydration_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/workout_provider.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/new_workout_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/progress_screen.dart';
import 'services/reminder_service.dart';
import 'theme/app_theme.dart';

void main() async {
  // Necessário antes de usar plugins nativos (SharedPreferences,
  // notificações) fora do runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Etapa 7: os estados globais são criados uma única vez aqui e
  // carregados ANTES do app abrir, para a primeira tela já mostrar os dados.
  final settings = SettingsProvider();
  await settings.carregar();

  final hydration = HydrationProvider(settings, NotificationReminderService());
  await hydration.carregar();

  final workouts = WorkoutProvider();
  await workouts.init(); // cache local + sincronização em segundo plano

  runApp(
    // MultiProvider coloca os estados no topo da árvore de widgets:
    // qualquer tela abaixo dele consegue ler e reagir a mudanças.
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: hydration),
        ChangeNotifierProvider.value(value: workouts),
      ],
      child: const TreinoLogApp(),
    ),
  );
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
  late final AppLifecycleListener _ciclodeVida;

  static const _abas = [
    ('Início', Icons.home, 'Resumo do dia e hidratação'),
    ('Novo Treino', Icons.add_circle_outline, 'Registrar um novo treino'),
    ('Histórico', Icons.history, 'Ver treinos já registrados'),
    ('Progresso', Icons.show_chart, 'Ver evolução de carga por exercício'),
    ('Perfil', Icons.person, 'Perfil, meta de água e lembretes'),
  ];

  @override
  void initState() {
    super.initState();
    // Quando o app volta para a tela: zera a água se o dia mudou e confere
    // se a permissão de notificações foi alterada nas configurações do Android.
    _ciclodeVida = AppLifecycleListener(
      onResume: () => context.read<HydrationProvider>().aoVoltarParaApp(),
    );
  }

  @override
  void dispose() {
    _ciclodeVida.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const List<Widget> screens = [
      HomeScreen(),
      NewWorkoutScreen(),
      HistoryScreen(),
      ProgressScreen(),
      ProfileScreen(),
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
