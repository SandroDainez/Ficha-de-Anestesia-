import 'package:flutter/material.dart';

import 'card_widget.dart';

class EventListWidget extends StatelessWidget {
  const EventListWidget({super.key, required this.events});

  final List<String> events;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: events.length,
      separatorBuilder: (context, index) => const Divider(height: 20),
      itemBuilder: (context, index) {
        final parts = events[index].split('|');
        final hasStructuredData = parts.length >= 2;
        final time = hasStructuredData
            ? (parts[0].isEmpty ? '--:--' : parts[0])
            : events[index].split(' ').first;
        final title = hasStructuredData
            ? parts[1]
            : events[index].split(' ').skip(1).join(' ');
        final description = hasStructuredData
            ? (parts.length > 2 && parts[2].trim().isNotEmpty
                  ? parts[2]
                  : 'Sem detalhes adicionais.')
            : (index == 0
                  ? 'Propofol 150 mg, Fentanil 100 mcg, Rocurônio 50 mg.'
                  : index == 1
                  ? 'Tubo 7,0 cm com videolaringoscópio.'
                  : index == 2
                  ? 'PAM 58 mmHg. Tratado com efedrina 10 mg.'
                  : 'Início do procedimento.');
        return EventRow(time: time, title: title, description: description);
      },
    );
  }
}

class EventRow extends StatelessWidget {
  const EventRow({
    super.key,
    required this.time,
    required this.title,
    required this.description,
  });

  final String time;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final isCritical = title.toLowerCase().contains('hipotensão');
    final isSuccess = title.toLowerCase().contains('incisão');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 46,
          child: Text(
            time,
            style: const TextStyle(
              color: Color(0xFF53677D),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        Container(
          width: 8,
          margin: const EdgeInsets.only(top: 3),
          child: const Icon(Icons.circle, size: 6, color: Color(0xFFD5E0EC)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SoftTag(
                text: title.toUpperCase(),
                color: isCritical
                    ? const Color(0xFFFFE9E9)
                    : isSuccess
                    ? const Color(0xFFE4F7EA)
                    : const Color(0xFFEAF2FF),
                textColor: isCritical
                    ? const Color(0xFFDD3B3B)
                    : isSuccess
                    ? const Color(0xFF169653)
                    : const Color(0xFF2B76D2),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF5D7288),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
