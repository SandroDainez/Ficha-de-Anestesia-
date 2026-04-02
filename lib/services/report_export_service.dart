import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/anesthesia_case.dart';
import '../models/anesthesia_record.dart';
import '../models/patient.dart';

class ReportExportService {
  const ReportExportService();

  Future<Uint8List> buildCasePdf({
    required AnesthesiaRecord record,
    required AnesthesiaCaseStatus status,
    String? caseId,
  }) async {
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final pdf = pw.Document(
      title: 'Ficha de Anestesia',
      author: 'anestesia_app',
      subject: 'Registro anestésico',
    );

    final generatedAt = DateTime.now();
    final patientName = record.patient.name.trim().isEmpty
        ? 'Paciente sem identificação'
        : record.patient.name.trim();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(
            base: regularFont,
            bold: boldFont,
          ),
        ),
        build: (context) => [
          _buildHeader(
            patientName: patientName,
            status: status.label,
            caseId: caseId,
            generatedAt: generatedAt,
          ),
          _buildPatientSummary(record),
          _section(
            'Identificação do paciente',
            [
              _field('Nome', patientName),
              _field('Perfil', record.patient.population.label),
              _field('Idade', _orDash(record.patient.age > 0 ? '${record.patient.age} anos' : '')),
              _field('Peso', _orDash(record.patient.weightKg > 0 ? '${record.patient.weightKg.toStringAsFixed(0)} kg' : '')),
              _field('Altura', _orDash(record.patient.heightMeters > 0 ? '${record.patient.heightMeters.toStringAsFixed(2).replaceAll('.', ',')} m' : '')),
              _field('ASA', _orDash(record.patient.asa)),
              _field('Alergias', _joinList(record.patient.allergies)),
              _field('Restrições', _joinList(record.patient.restrictions)),
              _field('Medicações em uso', _joinList(record.patient.medications)),
            ],
          ),
          _section(
            'Pré-anestésico',
            [
              _field('Comorbidades', _joinList(record.preAnestheticAssessment.comorbidities)),
              _field('Outras comorbidades', _orDash(record.preAnestheticAssessment.otherComorbidities)),
              _field('METS', _orDash(record.preAnestheticAssessment.mets)),
              _field('Exame físico', _orDash(record.preAnestheticAssessment.physicalExam)),
              _field('Prioridade do caso', _orDash(record.preAnestheticAssessment.surgeryPriority)),
              _field('Plano anestésico', _orDash(record.preAnestheticAssessment.anestheticPlan)),
              _field('Outros detalhes do plano', _orDash(record.preAnestheticAssessment.otherAnestheticPlan)),
              _field('Planejamento pós-operatório', _joinList(record.preAnestheticAssessment.postoperativePlanningItems)),
              _field('Outras medidas pós-operatórias', _orDash(record.preAnestheticAssessment.otherPostoperativePlanning)),
              _field('Anotações livres', _orDash(record.preAnestheticAssessment.planningNotes)),
              _field('Jejum sólidos', _orDash(record.preAnestheticAssessment.fastingSolids)),
              _field('Jejum líquidos', _orDash(record.preAnestheticAssessment.fastingLiquids)),
              _field('Jejum leite materno', _orDash(record.preAnestheticAssessment.fastingBreastMilk)),
              _field('Observações do jejum', _orDash(record.preAnestheticAssessment.fastingNotes)),
              _field('Exames complementares', _joinList(record.preAnestheticAssessment.complementaryExamItems)),
              _field('Outros exames', _orDash(record.preAnestheticAssessment.complementaryExams)),
            ],
          ),
          _section(
            'Cirurgia e segurança',
            [
              _field('Cirurgia', _orDash(record.surgeryDescription)),
              _field('Prioridade', _orDash(record.surgeryPriority)),
              _field('Cirurgião', _orDash(record.surgeonName)),
              _field('Auxiliares', _joinList(record.assistantNames)),
              _field('Destino pós-operatório', _orDash(record.patientDestination)),
              _field('Outro destino', _orDash(record.otherPatientDestination)),
              _field('Anotações operacionais', _orDash(record.operationalNotes)),
              _field('Porte cirúrgico', _orDash(record.surgicalSize)),
              _field('Time-out', record.timeOutCompleted ? 'Concluído' : 'Pendente'),
              _field('Checklist seguro', _joinList(record.safeSurgeryChecklist)),
              _field('Checklist de time-out', _joinList(record.timeOutChecklist)),
              _field('Jejum informado', _orDash(record.fastingHours)),
              _field('Antibioticoprofilaxia', _joinList(record.prophylacticAntibiotics)),
            ],
          ),
          _section(
            'Via aérea e monitorização',
            [
              _field('Mallampati', _orDash(record.airway.mallampati)),
              _field('Cormack-Lehane', _orDash(record.airway.cormackLehane)),
              _field('Dispositivo', _orDash(_joinParts([record.airway.device, record.airway.tubeNumber]))),
              _field('Técnica', _orDash(record.airway.technique)),
              _field('Observações', _orDash(record.airway.observation)),
              _field('Acessos venosos', _joinList(record.venousAccesses)),
              _field('Acessos arteriais', _joinList(record.arterialAccesses)),
              _field('Monitorização', _joinList(record.monitoringItems)),
            ],
          ),
          _section(
            'Técnica e medicações',
            [
              _field('Técnica anestésica', _orDash(record.anesthesiaTechnique)),
              _field('Indução / drogas', _joinList(record.drugs)),
              _field('Adjuvantes', _joinList(record.adjuncts)),
              _field('Outras medicações', _joinList(record.otherMedications)),
              _field('Drogas vasoativas', _joinList(record.vasoactiveDrugs)),
            ],
          ),
          _section(
            'Balanço hídrico',
            [
              _field('Cristaloides', _volume(record.fluidBalance.crystalloids)),
              _field('Coloides', _volume(record.fluidBalance.colloids)),
              _field('Sangue / derivados', _volume(record.fluidBalance.blood)),
              _field('Diurese', _volume(record.fluidBalance.diuresis)),
              _field('Sangramento', _volume(record.fluidBalance.bleeding)),
              _field(
                'Compressas',
                record.fluidBalance.spongeCount.trim().isEmpty
                    ? '--'
                    : '${record.fluidBalance.spongeCount} un (~${record.fluidBalance.estimatedSpongeLoss.toStringAsFixed(0)} mL)',
              ),
              _field('Outras perdas', _volume(record.fluidBalance.otherLosses)),
              _field('Balanço total', record.fluidBalance.formattedBalance),
            ],
          ),
          _section(
            'Eventos e hemodinâmica',
            [
              _field('Eventos intraoperatórios', _joinList(record.events)),
              _field('Marcadores hemodinâmicos', _joinHemodynamicMarkers(record)),
            ],
          ),
          if (record.hemodynamicPoints.isNotEmpty)
            _hemodynamicTable(record),
          _section(
            'Responsável',
            [
              _field('Anestesiologista', _orDash(record.anesthesiologistName)),
              _field('CRM', _orDash(record.anesthesiologistCrm)),
              _field('Detalhes', _orDash(record.anesthesiologistDetails)),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  String buildFileName(AnesthesiaRecord record) {
    final baseName = record.patient.name.trim().isEmpty
        ? 'ficha_anestesia'
        : record.patient.name
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
            .replaceAll(RegExp(r'_+'), '_')
            .replaceAll(RegExp(r'^_|_$'), '');
    final date = DateTime.now().toIso8601String().split('T').first;
    return '${baseName.isEmpty ? 'ficha_anestesia' : baseName}_$date.pdf';
  }

  String buildCaseJson({
    required AnesthesiaRecord record,
    required AnesthesiaCaseStatus status,
    String? caseId,
  }) {
    final payload = {
      'caseId': caseId,
      'status': status.code,
      'patient': record.patient.toJson(),
      'preAnesthetic': record.preAnestheticAssessment.toJson(),
      'surgery': {
        'description': record.surgeryDescription,
        'surgeon': record.surgeonName,
        'assistants': record.assistantNames,
      },
      'airway': record.airway.toJson(),
      'fluidBalance': record.fluidBalance.toJson(),
      'hemodynamic': {
        'points': record.hemodynamicPoints.map((point) => point.toJson()).toList(),
        'markers': record.hemodynamicMarkers.map((marker) => marker.toJson()).toList(),
      },
      'drugs': {
        'technique': record.anesthesiaTechnique,
        'drugs': record.drugs,
        'adjuncts': record.adjuncts,
        'otherMedications': record.otherMedications,
        'vasoactive': record.vasoactiveDrugs,
      },
      'events': record.events,
      'anesthesiologist': {
        'name': record.anesthesiologistName,
        'crm': record.anesthesiologistCrm,
        'details': record.anesthesiologistDetails,
      },
      'createdAt': DateTime.now().toIso8601String(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  pw.Widget _buildHeader({
    required String patientName,
    required String status,
    required String? caseId,
    required DateTime generatedAt,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 18),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Ficha de Anestesia',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            patientName,
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Status: $status'),
          if (caseId != null && caseId.isNotEmpty) pw.Text('Caso: $caseId'),
          pw.Text(
            'Gerado em ${_formatDateTime(generatedAt)}',
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPatientSummary(AnesthesiaRecord record) {
    final items = <List<String>>[
      ['ASA', _orDash(record.patient.asa)],
      ['Perfil', record.patient.population.label],
      ['Idade', _orDash(record.patient.age > 0 ? '${record.patient.age} anos' : '')],
      ['Peso', _orDash(record.patient.weightKg > 0 ? '${record.patient.weightKg.toStringAsFixed(0)} kg' : '')],
      ['Altura', _orDash(record.patient.heightMeters > 0 ? '${record.patient.heightMeters.toStringAsFixed(2).replaceAll('.', ',')} m' : '')],
      ['Status', _orDash(record.surgeryDescription.isNotEmpty ? 'Caso cirúrgico aberto' : 'Sem cirurgia informada')],
    ];

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map(
              (item) => pw.Container(
                width: 160,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item[0],
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.blueGrey700,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      item[1],
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  pw.Widget _section(String title, List<pw.Widget> children) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _field(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(text: value.trim().isEmpty ? '--' : value),
          ],
        ),
      ),
    );
  }

  pw.Widget _hemodynamicTable(AnesthesiaRecord record) {
    final grouped = <String, Map<String, String>>{};
    for (final point in record.hemodynamicPoints) {
      final timeKey = point.time.toStringAsFixed(0);
      final bucket = grouped.putIfAbsent(
        timeKey,
        () => {
          'tempo': '$timeKey min',
          'pas': '--',
          'pad': '--',
          'pam': '--',
          'fc': '--',
          'spo2': '--',
          'pai': '--',
        },
      );
      switch (point.type) {
        case 'PAS':
          bucket['pas'] = point.value.toStringAsFixed(0);
          break;
        case 'PAD':
          bucket['pad'] = point.value.toStringAsFixed(0);
          if (bucket['pas'] != '--') {
            final pas = double.tryParse(bucket['pas'] ?? '');
            final pad = double.tryParse(bucket['pad'] ?? '');
            if (pas != null && pad != null) {
              bucket['pam'] = ((pas + (2 * pad)) / 3).toStringAsFixed(0);
            }
          }
          break;
        case 'FC':
          bucket['fc'] = point.value.toStringAsFixed(0);
          break;
        case 'SpO2':
          bucket['spo2'] = point.value.toStringAsFixed(0);
          break;
        case 'PAI':
          bucket['pai'] = point.value.toStringAsFixed(0);
          break;
      }
    }

    final rows = grouped.entries.toList()
      ..sort((a, b) => double.parse(a.key).compareTo(double.parse(b.key)));

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Tabela hemodinâmica',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey700,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const ['Tempo', 'PAS', 'PAD', 'PAM', 'FC', 'SpO2', 'PAI'],
            data: rows
                .map(
                  (entry) => [
                    entry.value['tempo'] ?? '--',
                    entry.value['pas'] ?? '--',
                    entry.value['pad'] ?? '--',
                    entry.value['pam'] ?? '--',
                    entry.value['fc'] ?? '--',
                    entry.value['spo2'] ?? '--',
                    entry.value['pai'] ?? '--',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  static String _joinList(List<String> items) {
    final cleaned = items.map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    if (cleaned.isEmpty) return '--';
    return cleaned.join(', ');
  }

  static String _joinParts(List<String> parts) {
    final cleaned = parts.map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    if (cleaned.isEmpty) return '';
    return cleaned.join(' ');
  }

  static String _orDash(String value) {
    return value.trim().isEmpty ? '--' : value.trim();
  }

  static String _volume(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '--';
    return '$trimmed mL';
  }

  static String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year às $hour:$minute';
  }

  static String _joinHemodynamicMarkers(AnesthesiaRecord record) {
    if (record.hemodynamicMarkers.isEmpty) return '--';
    return record.hemodynamicMarkers
        .map((item) => '${item.label} (${item.recordedAtIso})')
        .join(', ');
  }
}
