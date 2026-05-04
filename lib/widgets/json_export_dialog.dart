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
      backgroundColor: const Color(0xFFF3F6FC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      titlePadding: const EdgeInsets.fromLTRB(56, 40, 56, 0),
      contentPadding: const EdgeInsets.fromLTRB(56, 28, 56, 24),
      actionsPadding: const EdgeInsets.fromLTRB(40, 0, 40, 30),
      title: const Text(
        'Resumo estruturado',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w400,
          color: Color(0xFF1F2630),
        ),
      ),
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
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
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
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF3C6C9C),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: content));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Resumo copiado para a área de transferência'),
              ),
            );
          },
          child: const Text('Copiar resumo'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF3C6C9C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
