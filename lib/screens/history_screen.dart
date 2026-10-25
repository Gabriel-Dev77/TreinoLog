import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../services/api_service.dart';
import '../services/feedback_service.dart';
import '../services/workout_store.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/exercise_tile.dart';
import '../widgets/offline_banner.dart';
import '../widgets/responsive_container.dart';
import 'workout_details_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  /// Busca os treinos no servidor ao abrir a tela.
  Future<void> _carregar() async {
    try {
      await WorkoutStore.refresh();
      _erro = null;
    } on ApiException catch (e) {
      _erro = e.mensagem;
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  /// "Puxar para atualizar".
  Future<void> _atualizar() async {
    try {
      await WorkoutStore.refresh();
      if (mounted) setState(() => _erro = null);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.mensagem);
      FeedbackService.error(context, e.mensagem);
    }
  }

  Future<void> _confirmarExclusao(Workout workout) async {
    if (!await confirmarExclusaoDeTreino(context)) return;

    try {
      await WorkoutStore.removeWorkout(workout);
      if (mounted) FeedbackService.success(context, 'Treino excluído');
    } on ApiException catch (e) {
      if (mounted) FeedbackService.error(context, e.mensagem);
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

  /// Mensagem centralizada que ainda permite "puxar para atualizar".
  Widget _buildMensagem(String texto, {bool comBotao = false}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      children: [
        const SizedBox(height: 80),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        if (comBotao) ...[
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _carregando = true);
                _carregar();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ),
        ],
      ],
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} às '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildConteudo() {
    // Mais recentes primeiro.
    final workouts = WorkoutStore.workouts.reversed.toList();

    if (_carregando && workouts.isEmpty) return _buildSkeleton();

    if (workouts.isEmpty) {
      return _erro != null
          ? _buildMensagem('Não foi possível carregar os treinos.\n$_erro', comBotao: true)
          : _buildMensagem('Nenhum treino registrado ainda.\nVá até "Novo Treino" para começar!');
    }

    return ResponsiveContainer(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          final workout = workouts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutDetailsScreen(workoutId: workout.id),
                  ),
                );
              },
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
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmarExclusao(workout),
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          tooltip: 'Excluir treino',
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
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Treinos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar lista',
            onPressed: _atualizar,
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _atualizar,
              // Redesenha sempre que a lista de treinos mudar
              // (novo treino salvo, edição, exclusão).
              child: ValueListenableBuilder<int>(
                valueListenable: WorkoutStore.changes,
                builder: (context, _, _) => _buildConteudo(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
