import 'package:flutter/material.dart';

/// Diálogo de confirmação para excluir um treino.
/// Retorna true só se o usuário tocar em "Excluir".
Future<bool> confirmarExclusaoDeTreino(BuildContext context) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Excluir treino?'),
      content: const Text(
        'O treino será apagado do servidor. Esta ação não pode ser desfeita.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  return confirmou == true;
}
