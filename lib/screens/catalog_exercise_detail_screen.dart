import 'package:flutter/material.dart';

import '../models/catalog_exercise.dart';
import '../models/request_state.dart';
import '../services/wger_service.dart';
import '../widgets/catalog_image.dart';
import '../widgets/request_state_view.dart';
import '../widgets/responsive_container.dart';

/// Detalhes de um exercício do catálogo wger.
///
/// Sempre consulta o exercício pelo id (`GET /exerciseinfo/<id>/`), o que
/// permite abrir esta tela também a partir de um treino salvo, que só
/// guarda o `wgerId`.
class CatalogExerciseDetailScreen extends StatefulWidget {
  final int exerciseId;

  /// Dados já conhecidos (vindos da lista), usados no título enquanto carrega.
  final CatalogExercise? previa;
  final bool modoSelecao;

  const CatalogExerciseDetailScreen({
    super.key,
    required this.exerciseId,
    this.previa,
    this.modoSelecao = false,
  });

  @override
  State<CatalogExerciseDetailScreen> createState() => _CatalogExerciseDetailScreenState();
}

class _CatalogExerciseDetailScreenState extends State<CatalogExerciseDetailScreen> {
  RequestState<CatalogExercise> _estado = const RequestLoading();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _estado = const RequestLoading());
    try {
      final exercicio = await WgerService.buscarPorId(widget.exerciseId);
      if (mounted) setState(() => _estado = RequestSuccess(exercicio));
    } on WgerException catch (e) {
      if (mounted) setState(() => _estado = RequestError(e.mensagem));
    }
  }

  Widget _secao(BuildContext context, String titulo, List<String> itens) {
    if (itens.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: itens.map((i) => Chip(label: Text(i))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalhes(BuildContext context, CatalogExercise ex) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (ex.imagemUrl != null)
          Center(child: CatalogImage(url: ex.imagemUrl, size: 220, fit: BoxFit.contain)),
        const SizedBox(height: 16),
        Text(ex.nome, style: Theme.of(context).textTheme.headlineSmall),
        if (ex.nomeIngles != null)
          Text(ex.nomeIngles!, style: Theme.of(context).textTheme.bodyMedium),
        if (ex.categoria.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Categoria: ${ex.categoria}'),
        ],
        _secao(context, 'Músculos principais', ex.musculos),
        _secao(context, 'Músculos secundários', ex.musculosSecundarios),
        _secao(context, 'Equipamentos', ex.equipamentos),
        const SizedBox(height: 16),
        Text('Como executar', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          ex.descricao.isEmpty
              ? 'O catálogo não tem descrição para este exercício.'
              : ex.descricao,
        ),
        const SizedBox(height: 24),
        Text(
          'Fonte: wger.de (dados abertos, licença CC-BY-SA)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (widget.modoSelecao) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, ex),
              icon: const Icon(Icons.add),
              label: const Text('Usar no treino'),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.previa?.nome ?? 'Exercício do catálogo')),
      body: ResponsiveContainer(
        child: RequestStateView<CatalogExercise>(
          state: _estado,
          onRetry: _carregar,
          mensagemCarregando: 'Carregando detalhes do exercício...',
          onSuccess: _buildDetalhes,
        ),
      ),
    );
  }
}
