import 'package:flutter/material.dart';

import '../models/request_state.dart';

/// Desenha a tela certa para cada estado de uma requisição:
/// carregando, sucesso, erro, sem dados ou ainda não iniciada.
///
/// Assim todas as telas que consultam serviços externos mostram os
/// estados do mesmo jeito.
class RequestStateView<T> extends StatelessWidget {
  final RequestState<T> state;
  final Widget Function(BuildContext context, T data) onSuccess;
  final VoidCallback? onRetry;
  final String mensagemCarregando;
  final String mensagemVazio;
  final String? mensagemInicial;
  final IconData iconeInicial;

  const RequestStateView({
    super.key,
    required this.state,
    required this.onSuccess,
    this.onRetry,
    this.mensagemCarregando = 'Carregando...',
    this.mensagemVazio = 'Nenhum dado encontrado.',
    this.mensagemInicial,
    this.iconeInicial = Icons.search,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      RequestIdle<T>() => _Mensagem(
          icone: iconeInicial,
          texto: mensagemInicial ?? '',
        ),
      RequestLoading<T>() => Semantics(
          liveRegion: true,
          label: mensagemCarregando,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                ExcludeSemantics(child: Text(mensagemCarregando)),
              ],
            ),
          ),
        ),
      RequestSuccess<T>(:final data) => onSuccess(context, data),
      RequestEmpty<T>() => _Mensagem(
          icone: Icons.search_off,
          texto: mensagemVazio,
        ),
      RequestError<T>(:final mensagem) => _Mensagem(
          icone: Icons.cloud_off,
          cor: Theme.of(context).colorScheme.error,
          texto: mensagem,
          acao: onRetry == null
              ? null
              : OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
        ),
    };
  }
}

class _Mensagem extends StatelessWidget {
  final IconData icone;
  final String texto;
  final Color? cor;
  final Widget? acao;

  const _Mensagem({required this.icone, required this.texto, this.cor, this.acao});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(icone, size: 56, color: cor ?? Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(
                texto,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              if (acao != null) ...[
                const SizedBox(height: 16),
                acao!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
