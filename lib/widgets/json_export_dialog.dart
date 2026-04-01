import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JsonExportDialog extends StatelessWidget {
  const JsonExportDialog({
    super.key,
    required this.json,
    required this.subject,
  });

  final String json;
  final String subject;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exportar JSON'),
      content: SizedBox(
        width: double.infinity,
        height: 360,
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: SelectableText(
                    json,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: json));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('JSON copiado para a área de transferência')),
            );
          },
          child: const Text('Copiar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
