import 'dart:async';

import 'package:flutter/material.dart';

import '../config/wger_config.dart';
import '../models/catalog_exercise.dart';
import '../models/request_state.dart';
import '../services/wger_service.dart';
import '../widgets/catalog_image.dart';
import '../widgets/request_state_view.dart';
import '../widgets/responsive_container.dart';
import 'catalog_exercise_detail_screen.dart';

/// Catálogo de exercícios (serviço externo wger).
///
/// - Modo navegação: o usuário pesquisa e vê detalhes dos exercícios.
/// - Modo seleção ([modoSelecao] = true): aberto a partir dos formulários de
///   treino; ao escolher um exercício, a tela fecha devolvendo o
///   [CatalogExercise] escolhido.
class ExerciseCatalogScreen extends StatefulWidget {
  final bool modoSelecao;
  final String termoInicial;

  const ExerciseCatalogScreen({super.key, this.modoSelecao = false, this.termoInicial = ''});

  @override
  State<ExerciseCatalogScreen> createState() => _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends State<ExerciseCatalogScreen> {
  late final TextEditingController _busca;
  Timer? _debounce;
  RequestState<List<CatalogExercise>> _estado = const RequestIdle();

  /// Número da busca mais recente. Respostas de buscas antigas que chegarem
  /// atrasadas são descartadas, para não sobrescrever o resultado atual.
  int _buscaAtual = 0;

  @override
  void initState() {
    super.initState();
    _busca = TextEditingController(text: widget.termoInicial);
    if (widget.termoInicial.trim().length >= WgerConfig.minimoCaracteres) {
      _buscar();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busca.dispose();
    super.dispose();
  }

  /// Espera o usuário parar de digitar antes de consultar a API,
  /// evitando uma requisição a cada letra.
  void _aoDigitar(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _buscar);
  }

  Future<void> _buscar() async {
    _debounce?.cancel();
    final termo = _busca.text.trim();

    if (termo.length < WgerConfig.minimoCaracteres) {
      setState(() {
        _buscaAtual++;
        _estado = const RequestIdle();
      });
      return;
    }

    final numero = ++_buscaAtual;
    setState(() => _estado = const RequestLoading());

    RequestState<List<CatalogExercise>> novo;
    try {
      final resultados = await WgerService.buscarExercicios(termo);
      novo = resultados.isEmpty ? const RequestEmpty() : RequestSuccess(resultados);
    } on WgerException catch (e) {
      novo = RequestError(e.mensagem);
    }

    if (!mounted || numero != _buscaAtual) return; // resposta antiga
    setState(() => _estado = novo);
  }

  Future<void> _abrirDetalhes(CatalogExercise exercicio) async {
    final escolhido = await Navigator.push<CatalogExercise>(
      context,
      MaterialPageRoute(
        builder: (_) => CatalogExerciseDetailScreen(
          exerciseId: exercicio.id,
          previa: exercicio,
          modoSelecao: widget.modoSelecao,
        ),
      ),
    );
    // No modo seleção, o "Usar no treino" da tela de detalhes devolve o exercício.
    if (escolhido != null && mounted) Navigator.pop(context, escolhido);
  }

  Widget _buildLista(BuildContext context, List<CatalogExercise> exercicios) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: exercicios.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            '${exercicios.length} resultado(s) do catálogo wger',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        final ex = exercicios[index - 1];
        final detalhes = [
          if (ex.categoria.isNotEmpty) ex.categoria,
          if (ex.musculos.isNotEmpty) ex.musculos.take(2).join(', '),
        ].join(' · ');

        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: CatalogImage(url: ex.miniaturaUrl),
            title: Text(ex.nome),
            subtitle: Text(
              [if (ex.nomeIngles != null) ex.nomeIngles!, if (detalhes.isNotEmpty) detalhes]
                  .join('\n'),
            ),
            isThreeLine: ex.nomeIngles != null && detalhes.isNotEmpty,
            onTap: () => _abrirDetalhes(ex),
            trailing: widget.modoSelecao
                ? IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Usar ${ex.nome} no treino',
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => Navigator.pop(context, ex),
                  )
                : const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modoSelecao ? 'Escolher exercício' : 'Catálogo de exercícios'),
      ),
      body: ResponsiveContainer(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _busca,
                autofocus: widget.termoInicial.isEmpty,
                textInputAction: TextInputAction.search,
                onChanged: _aoDigitar,
                onSubmitted: (_) => _buscar(),
                decoration: InputDecoration(
                  labelText: 'Buscar exercício',
                  hintText: 'Ex: supino, agachamento, bench press',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _busca,
                    builder: (context, valor, _) => valor.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Limpar busca',
                            onPressed: () {
                              _busca.clear();
                              _buscar();
                            },
                          ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: RequestStateView<List<CatalogExercise>>(
                state: _estado,
                onRetry: _buscar,
                mensagemInicial:
                    'Digite pelo menos ${WgerConfig.minimoCaracteres} letras para buscar '
                    'no catálogo público de exercícios.',
                mensagemCarregando: 'Buscando no catálogo...',
                mensagemVazio: 'Nenhum exercício encontrado para "${_busca.text.trim()}".\n'
                    'O catálogo tem mais exercícios em inglês: tente, por exemplo, '
                    '"bench press" ou "squat".',
                onSuccess: _buildLista,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
