import 'package:flutter/material.dart';

// Limita a largura do conteúdo em telas grandes (tablet/desktop/web),
// evitando que o layout fique esticado. Em celulares, ocupa a tela toda.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 700,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}