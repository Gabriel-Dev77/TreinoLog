import 'package:flutter/material.dart';

/// Imagem de um exercício do catálogo wger, com espaço reservado
/// enquanto carrega e um ícone quando não há imagem ou ela falha.
class CatalogImage extends StatelessWidget {
  final String? url;
  final double size;
  final BoxFit fit;

  const CatalogImage({super.key, required this.url, this.size = 56, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: Colors.grey.shade200,
      child: Icon(Icons.fitness_center, color: Colors.grey.shade500, size: size * 0.45),
    );

    // Muitos exercícios do catálogo não têm imagem.
    if (url == null) return ExcludeSemantics(child: placeholder);

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url!,
          width: size,
          height: size,
          fit: fit,
          // No Flutter Web, as imagens do wger não liberam CORS; o fallback
          // exibe a imagem como elemento <img> do navegador nesses casos.
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          loadingBuilder: (context, child, progresso) =>
              progresso == null ? child : placeholder,
          errorBuilder: (context, erro, stack) => placeholder,
        ),
      ),
    );
  }
}
