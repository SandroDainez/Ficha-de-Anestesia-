import 'package:flutter/material.dart';

import '../models/record_analysis.dart';

class FooterBar extends StatelessWidget {
  const FooterBar({
    super.key,
    required this.anesthesiologistName,
    required this.anesthesiologistCrm,
    required this.anesthesiologistDetails,
    required this.onDoctorTap,
    required this.onVerifyPressed,
    required this.onFinalizePressed,
  });

  final String anesthesiologistName;
  final String anesthesiologistCrm;
  final String anesthesiologistDetails;
  final Future<void> Function() onDoctorTap;
  final Future<void> Function() onVerifyPressed;
  final Future<void> Function() onFinalizePressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 280,
          child: DoctorCard(
            name: anesthesiologistName,
            crm: anesthesiologistCrm,
            details: anesthesiologistDetails,
            onTap: onDoctorTap,
          ),
        ),
        SizedBox(
          width: 360,
          child: PrimaryFooterButton(
            key: const Key('verify-record-button'),
            label: 'VERIFICAR FICHA COM IA',
            subtitle: 'Auditoria automática',
            color: const Color(0xFF2B76D2),
            onPressed: onVerifyPressed,
          ),
        ),
        SizedBox(
          width: 280,
          child: PrimaryFooterButton(
            key: const Key('finalize-case-button'),
            label: 'FINALIZAR CASO',
            subtitle: 'Gerar relatório',
            color: const Color(0xFF169653),
            onPressed: onFinalizePressed,
          ),
        ),
      ],
    );
  }
}

class PrimaryFooterButton extends StatelessWidget {
  const PrimaryFooterButton({
    super.key,
    required this.label,
    required this.subtitle,
    required this.color,
    this.onPressed,
  });

  final String label;
  final String subtitle;
  final Color color;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed == null ? null : () => onPressed!.call(),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size.fromHeight(72),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  const DoctorCard({
    super.key,
    required this.name,
    required this.crm,
    required this.details,
    required this.onTap,
  });

  final String name;
  final String crm;
  final String details;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'Toque para preencher' : name;
    final displaySubtitle = [
      if (crm.trim().isNotEmpty) 'CRM $crm',
      if (details.trim().isNotEmpty) details,
    ].join(' • ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCE6F2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF2B76D2)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ANESTESIOLOGISTA RESPONSÁVEL',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF2B76D2),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF17324D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (displaySubtitle.isNotEmpty)
                      Text(
                        displaySubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF5D7288),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecordAnalysisDialog extends StatelessWidget {
  const RecordAnalysisDialog({
    super.key,
    required this.analysis,
  });

  final RecordAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final headerColor =
        analysis.isComplete ? const Color(0xFF169653) : const Color(0xFFCC3D3D);

    return AlertDialog(
      backgroundColor: const Color(0xFFF9FBFE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Icon(
            analysis.isComplete ? Icons.check_circle : Icons.warning_amber_rounded,
            color: headerColor,
          ),
          const SizedBox(width: 8),
          const Expanded(child: Text('Análise da ficha')),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                analysis.summary,
                style: const TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (analysis.missingFields.isNotEmpty) ...[
                const SizedBox(height: 16),
                const _AnalysisSectionTitle(title: 'Campos pendentes'),
                const SizedBox(height: 8),
                ...analysis.missingFields.map((item) => _AnalysisBullet(text: item)),
              ],
              if (analysis.findings.isNotEmpty) ...[
                const SizedBox(height: 16),
                const _AnalysisSectionTitle(title: 'Achados'),
                const SizedBox(height: 8),
                ...analysis.findings.map((item) => _AnalysisBullet(text: item)),
              ],
              if (analysis.recommendations.isNotEmpty) ...[
                const SizedBox(height: 16),
                const _AnalysisSectionTitle(title: 'Recomendações'),
                const SizedBox(height: 8),
                ...analysis.recommendations
                    .map((item) => _AnalysisBullet(text: item)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class _AnalysisSectionTitle extends StatelessWidget {
  const _AnalysisSectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF17324D),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _AnalysisBullet extends StatelessWidget {
  const _AnalysisBullet({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 7, color: Color(0xFF2B76D2)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF5D7288),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
