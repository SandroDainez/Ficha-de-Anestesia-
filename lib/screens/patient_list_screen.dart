import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/anesthesia_case.dart';
import '../models/anesthesia_record.dart';
import '../models/patient.dart';
import '../services/record_storage_service.dart';
import '../services/report_export_service.dart';
import '../services/supabase_service.dart';
import '../widgets/json_export_dialog.dart';
import 'anesthesia_screen.dart';
import 'pre_anesthetic_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final RecordStorageService _storageService = RecordStorageService();
  final ReportExportService _reportExportService = const ReportExportService();

  List<AnesthesiaCase> _cases = const [];

  @override
  void initState() {
    super.initState();
    _reloadCases();
  }

  String _nowLabel() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Future<void> _reloadCases() async {
    final cases = await _storageService.loadCases();
    if (!mounted) return;
    setState(() {
      _cases = cases;
    });
  }

  Future<void> _openAnesthesiaRecord({AnesthesiaCase? caseFile}) async {
    final now = DateTime.now().toIso8601String();
    final targetCase = caseFile ??
        AnesthesiaCase(
          id: _storageService.createCaseId(),
          createdAtIso: now,
          updatedAtIso: now,
          preAnestheticDate: '',
          anesthesiaDate: _nowLabel(),
          status: AnesthesiaCaseStatus.inProgress,
          record: const AnesthesiaRecord.empty(),
        );

    final caseWithDate = targetCase.copyWith(
      anesthesiaDate: targetCase.anesthesiaDate.trim().isEmpty
          ? _nowLabel()
          : targetCase.anesthesiaDate,
    );
    if (!mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AnesthesiaScreen(
          initialRecord: caseWithDate.record,
          caseId: caseWithDate.id,
          initialCaseStatus: caseWithDate.status,
          createdAtIso: caseWithDate.createdAtIso,
          initialPreAnestheticDate: caseWithDate.preAnestheticDate,
          initialAnesthesiaDate: caseWithDate.anesthesiaDate,
        ),
      ),
    );

    await _reloadCases();
  }

  Future<void> _openPreAnesthetic({AnesthesiaCase? caseFile}) async {
    final currentRecord = caseFile?.record ?? const AnesthesiaRecord.empty();
    final result = await Navigator.of(context).push<PreAnestheticScreenResult>(
      MaterialPageRoute<PreAnestheticScreenResult>(
        builder: (_) => PreAnestheticScreen(
          patient: currentRecord.patient,
          initialAssessment: currentRecord.preAnestheticAssessment,
          initialConsultationDate: caseFile?.preAnestheticDate ?? _nowLabel(),
        ),
      ),
    );

    if (!mounted || result == null) return;

    final now = DateTime.now().toIso8601String();
    final updatedRecord = currentRecord.copyWith(
      patient: result.patient,
      preAnestheticAssessment: result.assessment,
      airway: result.assessment.airway,
    );
    final updatedCase = AnesthesiaCase(
      id: caseFile?.id ?? _storageService.createCaseId(),
      createdAtIso: caseFile?.createdAtIso ?? now,
      updatedAtIso: now,
      preAnestheticDate: result.consultationDate,
      anesthesiaDate: caseFile?.anesthesiaDate ?? '',
      status: caseFile?.status == AnesthesiaCaseStatus.finalized
          ? AnesthesiaCaseStatus.finalized
          : AnesthesiaCaseStatus.preAnesthetic,
      record: updatedRecord,
    );

    await _storageService.upsertCase(updatedCase);
    await _reloadCases();
  }

  Future<void> _deleteCase(AnesthesiaCase caseFile) async {
    await _storageService.deleteCase(caseFile.id);
    await _reloadCases();
  }

  Future<void> _exportCase(AnesthesiaCase caseFile) async {
    final bytes = await _reportExportService.buildCasePdf(
      record: caseFile.record,
      status: caseFile.status,
      caseId: caseFile.id,
    );
    if (!mounted) return;
    final fileName = _reportExportService.buildFileName(caseFile.record);
    await showDialog<void>(
      context: context,
      builder: (_) => _CaseExportDialog(
        onPreviewPressed: () =>
            Printing.layoutPdf(onLayout: (_) async => bytes),
        onSharePressed: () =>
            Printing.sharePdf(bytes: bytes, filename: fileName),
      ),
    );
  }

  Future<void> _exportCaseJson(AnesthesiaCase caseFile) async {
    final jsonText = _reportExportService.buildCaseJson(
      record: caseFile.record,
      status: caseFile.status,
      caseId: caseFile.id,
    );
    await showDialog<void>(
      context: context,
      builder: (_) => JsonExportDialog(
        content: jsonText,
        subject: 'Ficha ${caseFile.displayName}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preAnestheticCases = _cases
        .where((item) => item.status == AnesthesiaCaseStatus.preAnesthetic)
        .toList();
    final inProgressCases = _cases
        .where((item) => item.status == AnesthesiaCaseStatus.inProgress)
        .toList();
    final finalizedCases = _cases
        .where((item) => item.status == AnesthesiaCaseStatus.finalized)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Casos de Anestesia',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: RefreshIndicator(
            onRefresh: _reloadCases,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildCreatePanel(),
                const SizedBox(height: 20),
                if (_cases.isEmpty) _buildEmptyState(),
                if (preAnestheticCases.isNotEmpty)
                  _CaseSection(
                    title: 'Pré-anestésicos salvos',
                    subtitle:
                        'Consultas prontas para serem abertas no dia da cirurgia',
                    children: preAnestheticCases
                        .map(
                          (item) => _CaseTile(
                            caseFile: item,
                            onOpenPreAnesthetic: () =>
                                _openPreAnesthetic(caseFile: item),
                            onOpenAnesthesia: () =>
                                _openAnesthesiaRecord(caseFile: item),
                            onExport: () => _exportCase(item),
                            onExportJson: () => _exportCaseJson(item),
                            onDelete: () => _deleteCase(item),
                          ),
                        )
                        .toList(),
                  ),
                if (inProgressCases.isNotEmpty)
                  _CaseSection(
                    title: 'Casos em andamento',
                    subtitle: 'Fichas anestésicas já iniciadas',
                    children: inProgressCases
                        .map(
                          (item) => _CaseTile(
                            caseFile: item,
                            onOpenPreAnesthetic: () =>
                                _openPreAnesthetic(caseFile: item),
                            onOpenAnesthesia: () =>
                                _openAnesthesiaRecord(caseFile: item),
                            onExport: () => _exportCase(item),
                            onExportJson: () => _exportCaseJson(item),
                            onDelete: () => _deleteCase(item),
                          ),
                        )
                        .toList(),
                  ),
                if (finalizedCases.isNotEmpty)
                  _CaseSection(
                    title: 'Casos finalizados',
                    subtitle: 'Arquivo local de fichas completas já finalizadas',
                    children: finalizedCases
                        .map(
                          (item) => _CaseTile(
                            caseFile: item,
                            onOpenPreAnesthetic: () =>
                                _openPreAnesthetic(caseFile: item),
                            onOpenAnesthesia: () =>
                                _openAnesthesiaRecord(caseFile: item),
                            onExport: () => _exportCase(item),
                            onExportJson: () => _exportCaseJson(item),
                            onDelete: () => _deleteCase(item),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120B2540),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.folder_open_outlined,
            size: 46,
            color: Color(0xFF2B76D2),
          ),
          const SizedBox(height: 14),
          const Text(
            'Iniciar novo caso',
            style: TextStyle(
              color: Color(0xFF17324D),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Você pode salvar o pré-anestésico para abrir depois ou iniciar a ficha anestésica diretamente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF5F7288),
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: FilledButton.icon(
                  onPressed: () => _openAnesthesiaRecord(),
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Nova ficha anestésica'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
              ),
              SizedBox(
                width: 320,
                child: OutlinedButton.icon(
                  onPressed: () => _openPreAnesthetic(),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Novo pré-anestésico'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nenhum caso salvo ainda',
            style: TextStyle(
              color: Color(0xFF17324D),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Os casos preenchidos ficam guardados localmente neste dispositivo para reabrir depois.',
            style: TextStyle(
              color: Color(0xFF5F7288),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseSection extends StatelessWidget {
  const _CaseSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF6A7E94),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _CaseTile extends StatelessWidget {
  const _CaseTile({
    required this.caseFile,
    required this.onOpenPreAnesthetic,
    required this.onOpenAnesthesia,
    required this.onExport,
    required this.onDelete,
    required this.onExportJson,
  });

  final AnesthesiaCase caseFile;
  final VoidCallback onOpenPreAnesthetic;
  final VoidCallback onOpenAnesthesia;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback onExportJson;

  @override
  Widget build(BuildContext context) {
    final patient = caseFile.record.patient;
    final statusColor = switch (caseFile.status) {
      AnesthesiaCaseStatus.preAnesthetic => const Color(0xFFB07A1E),
      AnesthesiaCaseStatus.inProgress => const Color(0xFF2B76D2),
      AnesthesiaCaseStatus.finalized => const Color(0xFF168B79),
    };
    final populationLabel = patient.population.label;
    final supabaseOnline = SupabaseService.instance.isConfigured;
    final summaryParts = <String>[
      if (patient.age > 0) '${patient.age} anos',
      if (patient.weightKg > 0) '${patient.weightKg.toStringAsFixed(0)} kg',
      if (patient.asa.trim().isNotEmpty) 'ASA ${patient.asa}',
      populationLabel,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  caseFile.displayName,
                  style: const TextStyle(
                    color: Color(0xFF17324D),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  caseFile.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summaryParts.join(' • '),
            style: const TextStyle(
              color: Color(0xFF5F7288),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Atualizado em ${_formatDateTime(caseFile.updatedAtIso)}',
            style: const TextStyle(
              color: Color(0xFF7B8CA0),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                supabaseOnline ? Icons.cloud_done : Icons.cloud_off,
                size: 16,
                color: supabaseOnline ? const Color(0xFF169653) : const Color(0xFFB07A1E),
              ),
              const SizedBox(width: 6),
              Text(
                supabaseOnline ? 'Sincronizado no Supabase' : 'Sem conexão Supabase',
                style: TextStyle(
                  color: supabaseOnline ? const Color(0xFF169653) : const Color(0xFFB07A1E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: onOpenAnesthesia,
                icon: const Icon(Icons.assignment_outlined),
                label: Text(
                  caseFile.status == AnesthesiaCaseStatus.preAnesthetic
                      ? 'Abrir ficha anestésica'
                      : caseFile.status == AnesthesiaCaseStatus.finalized
                          ? 'Visualizar ficha'
                          : 'Continuar ficha',
                ),
              ),
              OutlinedButton.icon(
                onPressed: onOpenPreAnesthetic,
                icon: const Icon(Icons.description_outlined),
                label: const Text('Editar pré-anestésico'),
              ),
              OutlinedButton.icon(
                onPressed: onExport,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Exportar PDF'),
              ),
              OutlinedButton.icon(
                onPressed: onExportJson,
                icon: const Icon(Icons.code_outlined),
                label: const Text('Exportar JSON'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return '--';
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$day/$month/$year às $hour:$minute';
  }
}

class _CaseExportDialog extends StatelessWidget {
  const _CaseExportDialog({
    required this.onPreviewPressed,
    required this.onSharePressed,
  });

  final Future<void> Function() onPreviewPressed;
  final Future<void> Function() onSharePressed;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exportar caso'),
      content: const Text(
        'Você pode visualizar ou imprimir o PDF, ou compartilhar/salvar o arquivo para computador, WhatsApp ou email.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            Navigator.of(context).pop();
            await onPreviewPressed();
          },
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Visualizar / imprimir'),
        ),
        FilledButton.icon(
          onPressed: () async {
            Navigator.of(context).pop();
            await onSharePressed();
          },
          icon: const Icon(Icons.share_outlined),
          label: const Text('Compartilhar / salvar'),
        ),
      ],
    );
  }
}
