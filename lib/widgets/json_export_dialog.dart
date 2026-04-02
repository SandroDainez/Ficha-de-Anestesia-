import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JsonExportDialog extends StatelessWidget {
  const JsonExportDialog({
    super.key,
    required this.content,
    required this.subject,
  });

  final String content;
  final String subject;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Resumo estruturado'),
      content: SizedBox(
        width: double.infinity,
        height: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject,
              style: const TextStyle(
                color: Color(0xFF5D7288),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: SelectableText(
                    content,
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
            Clipboard.setData(ClipboardData(text: content));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Resumo copiado para a área de transferência')),
            );
          },
          child: const Text('Copiar resumo'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
