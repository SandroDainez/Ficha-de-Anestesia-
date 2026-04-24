import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/anesthesia_case.dart';
import '../models/anesthesia_record.dart';
import '../models/patient.dart';

class ReportExportService {
  const ReportExportService();

  @visibleForTesting
  bool shouldIncludeHemodynamicChart(AnesthesiaRecord record) {
    return record.hemodynamicPoints.isNotEmpty ||
        record.hemodynamicMarkers.isNotEmpty;
  }

  List<String> _resolveAnesthesiologists(AnesthesiaRecord record) {
    if (record.anesthesiologists.isNotEmpty) {
      return record.anesthesiologists
          .map(_formatAnesthesiologistEntry)
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }

    final fallback = _formatAnesthesiologistEntry(
      '${record.anesthesiologistName}|'
      '${record.anesthesiologistCrm}|'
      '${record.anesthesiologistDetails}',
    );
    return fallback.trim().isEmpty ? const [] : [fallback];
  }

  String _formatAnesthesiologistEntry(String rawEntry) {
    final parts = [...rawEntry.split('|'), '', ''];
    final name = parts[0].trim();
    final crm = parts[1].trim();
    final details = parts[2].trim();
    final segments = <String>[
      if (name.isNotEmpty) name,
      if (crm.isNotEmpty) 'CRM $crm',
      if (details.isNotEmpty) details,
    ];
    return segments.join(' • ');
  }

  Future<Uint8List> buildCasePdf({
    required AnesthesiaRecord record,
    required AnesthesiaCaseStatus status,
    String? caseId,
  }) async {
    final anesthesiologists = _resolveAnesthesiologists(record);
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
              _field(
                'Termo de Consentimento Informado para Anestesia',
                _orDash(record.patient.informedConsentStatus),
              ),
              _field('Alergias', _joinList(record.patient.allergies)),
              _field('Restrições', _joinList(record.patient.restrictions)),
              _field('Medicações em uso', _joinList(record.patient.medications)),
            ],
          ),
          _section(
            'Ficha de anestesia',
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
              _field('Agulhas neuraxiais', _joinList(record.neuraxialNeedles)),
              _field('Monitorização', _joinList(record.monitoringItems)),
            ],
          ),
          _section(
            'Técnica e medicações',
            [
              _field('Técnica anestésica', _orDash(record.anesthesiaTechnique)),
              _field(
                'Descrição da técnica',
                _orDash(record.anesthesiaTechniqueDetails),
              ),
              _field('Indução / drogas', _joinList(record.drugs)),
              _field('Adjuvantes', _joinList(record.adjuncts)),
              _field(
                'Sedação associada',
                _joinList(record.sedationMedications),
              ),
              _field('Outras medicações', _joinList(record.otherMedications)),
              _field('Drogas vasoativas', _joinList(record.vasoactiveDrugs)),
              _field('Materiais e consumos', _joinList(record.anesthesiaMaterials)),
            ],
          ),
          _section(
            'Saída da anestesia',
            [
              _field('Status de extubação / saída', _orDash(record.emergenceStatus)),
              _field('Condições e observações', _orDash(record.emergenceNotes)),
              _field('Destino pós-operatório', _orDash(record.patientDestination)),
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
              _field('Marcadores hemodinâmicos', _joinHemodynamicMarkers(record)),
            ],
          ),
          if (shouldIncludeHemodynamicChart(record))
            _hemodynamicChart(record),
          if (record.hemodynamicPoints.isNotEmpty)
            _hemodynamicTable(record),
          _section(
            'Recuperação pós-anestésica / pós-cirúrgica',
            [
              _field(
                'Horário de admissão',
                _orDash(record.postAnesthesiaRecovery.admissionTime),
              ),
              _field(
                'Critérios de admissão',
                _joinList(record.postAnesthesiaRecovery.admissionCriteria),
              ),
              _field(
                'Monitorização',
                _joinList(record.postAnesthesiaRecovery.monitoringItems),
              ),
              _field(
                'Dor',
                _orDash(record.postAnesthesiaRecovery.painScore),
              ),
              _field(
                'Náusea / vômito',
                _orDash(record.postAnesthesiaRecovery.nauseaScore),
              ),
              _field(
                'Sedação',
                _orDash(record.postAnesthesiaRecovery.sedationScale),
              ),
              _field(
                'Temperatura',
                _orDash(record.postAnesthesiaRecovery.temperature),
              ),
              _field(
                'Aldrete',
                record.postAnesthesiaRecovery.aldreteTotal == 0
                    ? '--'
                    : '${record.postAnesthesiaRecovery.aldreteTotal}/10',
              ),
              _field(
                'Complicações na recuperação',
                _joinList(record.postAnesthesiaRecovery.complications),
              ),
              _field(
                'Intervenções',
                _joinList(record.postAnesthesiaRecovery.interventions),
              ),
              _field(
                'Critérios de alta',
                _joinList(record.postAnesthesiaRecovery.dischargeCriteria),
              ),
              _field(
                'Horário de alta',
                _orDash(record.postAnesthesiaRecovery.dischargeTime),
              ),
              _field(
                'Destino após recuperação',
                _orDash(record.postAnesthesiaRecovery.destinationAfterRecovery),
              ),
              _field(
                'Admissão / handoff',
                _orDash(record.postAnesthesiaRecovery.admissionNotes),
              ),
              _field(
                'Condições de alta / orientações',
                _orDash(record.postAnesthesiaRecovery.dischargeNotes),
              ),
            ],
          ),
          _section(
            'Responsável',
            [
              _field(
                'Anestesiologistas',
                anesthesiologists.isEmpty ? '--' : anesthesiologists.join(' | '),
              ),
            ],
          ),
          _section(
            'Pré-anestésico',
            [
              _field('Comorbidades', _joinList(record.preAnestheticAssessment.comorbidities)),
              _field('Outras comorbidades', _orDash(record.preAnestheticAssessment.otherComorbidities)),
              _field('Capacidade funcional / reserva', _orDash(record.preAnestheticAssessment.mets)),
              _field('Exame físico', _orDash(record.preAnestheticAssessment.physicalExam)),
              _field('Prioridade do caso', _orDash(record.preAnestheticAssessment.surgeryPriority)),
              _field('Plano anestésico', _orDash(record.preAnestheticAssessment.anestheticPlan)),
              _field('Outros detalhes do plano', _orDash(record.preAnestheticAssessment.otherAnestheticPlan)),
              _field('Planejamento pós-operatório', _joinList(record.preAnestheticAssessment.postoperativePlanningItems)),
              _field('Outras medidas pós-operatórias', _orDash(record.preAnestheticAssessment.otherPostoperativePlanning)),
              _field('Anotações livres', _orDash(record.preAnestheticAssessment.planningNotes)),
              _field('Jejum sólidos / fórmula / refeição', _orDash(record.preAnestheticAssessment.fastingSolids)),
              _field('Jejum líquidos claros', _orDash(record.preAnestheticAssessment.fastingLiquids)),
              _field('Jejum leite materno', _orDash(record.preAnestheticAssessment.fastingBreastMilk)),
              _field('Observações do jejum', _orDash(record.preAnestheticAssessment.fastingNotes)),
              _field('Exames complementares', _joinList(record.preAnestheticAssessment.complementaryExamItems)),
              _field('Outros exames', _orDash(record.preAnestheticAssessment.complementaryExams)),
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
    final anesthesiologists = _resolveAnesthesiologists(record);
    final payload = {
      'identificacao': {
        'caso': caseId ?? 'Sem identificador',
        'status': status.label,
        'paciente': record.patient.name.trim().isEmpty ? 'Sem identificação' : record.patient.name.trim(),
        'perfil': record.patient.population.label,
        'idade': record.patient.age > 0 ? '${record.patient.age} anos' : 'Não informada',
        'peso': record.patient.weightKg > 0 ? '${record.patient.weightKg.toStringAsFixed(0)} kg' : 'Não informado',
        'altura': record.patient.heightMeters > 0 ? '${record.patient.heightMeters.toStringAsFixed(2).replaceAll('.', ',')} m' : 'Não informada',
        'asa': _orDash(record.patient.asa),
        'termo_de_consentimento_informado_para_anestesia':
            _orDash(record.patient.informedConsentStatus),
        'alergias': record.patient.allergies.isEmpty ? 'Nenhuma registrada' : record.patient.allergies.join(', '),
        'restricoes': record.patient.restrictions.isEmpty ? 'Nenhuma registrada' : record.patient.restrictions.join(', '),
        'medicacoes_em_uso': record.patient.medications.isEmpty ? 'Nenhuma registrada' : record.patient.medications.join(', '),
      },
      'ficha_de_anestesia': {
        'cirurgia': _orDash(record.surgeryDescription),
        'prioridade': _orDash(record.surgeryPriority),
        'cirurgiao': _orDash(record.surgeonName),
        'auxiliares': record.assistantNames.isEmpty ? 'Não informados' : record.assistantNames.join(', '),
        'destino_pos_operatorio': _orDash(record.patientDestination),
        'outro_destino': _orDash(record.otherPatientDestination),
        'chegada_ao_centro_cirurgico_e_anotacoes': _orDash(record.operationalNotes),
        'porte_cirurgico': _orDash(record.surgicalSize),
        'tecnica_anestesica': _orDash(record.anesthesiaTechnique),
        'descricao_da_tecnica_anestesica':
            _orDash(record.anesthesiaTechniqueDetails),
        'saida_da_anestesia': {
          'status': _orDash(record.emergenceStatus),
          'observacoes': _orDash(record.emergenceNotes),
        },
        'antibioticoprofilaxia': record.prophylacticAntibiotics.isEmpty ? 'Não registrada' : record.prophylacticAntibiotics.join(' | '),
        'jejum_informado': _orDash(record.fastingHours),
        'via_aerea': {
          'mallampati': _orDash(record.airway.mallampati),
          'cormack_lehane': _orDash(record.airway.cormackLehane),
          'dispositivo': _orDash(_joinParts([record.airway.device, record.airway.tubeNumber])),
          'tecnica': _orDash(record.airway.technique),
          'observacoes': _orDash(record.airway.observation),
        },
        'acessos_e_monitorizacao': {
          'acessos_venosos': record.venousAccesses.isEmpty ? 'Nenhum registrado' : record.venousAccesses.join(', '),
          'acessos_arteriais': record.arterialAccesses.isEmpty ? 'Nenhum registrado' : record.arterialAccesses.join(', '),
          'agulhas_neuraxiais': record.neuraxialNeedles.isEmpty ? 'Nenhuma registrada' : record.neuraxialNeedles.join(', '),
          'monitorizacao': record.monitoringItems.isEmpty ? 'Nenhuma registrada' : record.monitoringItems.join(', '),
        },
        'medicacoes_intraoperatorias': {
          'inducao': record.drugs.isEmpty ? 'Não registrada' : record.drugs.join(' | '),
          'adjuvantes': record.adjuncts.isEmpty ? 'Não registrados' : record.adjuncts.join(' | '),
          'sedacao_associada': record.sedationMedications.isEmpty
              ? 'Não registrada'
              : record.sedationMedications.join(' | '),
          'outras_medicacoes': record.otherMedications.isEmpty ? 'Não registradas' : record.otherMedications.join(' | '),
          'drogas_vasoativas': record.vasoactiveDrugs.isEmpty ? 'Não registradas' : record.vasoactiveDrugs.join(' | '),
          'materiais_e_consumos': record.anesthesiaMaterials.isEmpty
              ? 'Não registrados'
              : record.anesthesiaMaterials.join(' | '),
        },
        'balanco_hidrico': {
          'cristaloides': _volume(record.fluidBalance.crystalloids),
          'coloides': _volume(record.fluidBalance.colloids),
          'sangue_e_derivados': _volume(record.fluidBalance.blood),
          'diurese': _volume(record.fluidBalance.diuresis),
          'sangramento': _volume(record.fluidBalance.bleeding),
          'outras_perdas': _volume(record.fluidBalance.otherLosses),
          'balanco_total': record.fluidBalance.formattedBalance,
        },
        'recuperacao_pos_anestesica': {
          'horario_de_admissao':
              _orDash(record.postAnesthesiaRecovery.admissionTime),
          'criterios_de_admissao': record
                  .postAnesthesiaRecovery.admissionCriteria.isEmpty
              ? 'Não registrados'
              : record.postAnesthesiaRecovery.admissionCriteria.join(', '),
          'monitorizacao': record.postAnesthesiaRecovery.monitoringItems.isEmpty
              ? 'Não registrada'
              : record.postAnesthesiaRecovery.monitoringItems.join(', '),
          'dor': _orDash(record.postAnesthesiaRecovery.painScore),
          'nausea_vomito': _orDash(record.postAnesthesiaRecovery.nauseaScore),
          'sedacao': _orDash(record.postAnesthesiaRecovery.sedationScale),
          'temperatura': _orDash(record.postAnesthesiaRecovery.temperature),
          'aldrete_total': record.postAnesthesiaRecovery.aldreteTotal == 0
              ? '--'
              : '${record.postAnesthesiaRecovery.aldreteTotal}/10',
          'complicacoes': record.postAnesthesiaRecovery.complications.isEmpty
              ? 'Nenhuma registrada'
              : record.postAnesthesiaRecovery.complications.join(', '),
          'intervencoes': record.postAnesthesiaRecovery.interventions.isEmpty
              ? 'Nenhuma registrada'
              : record.postAnesthesiaRecovery.interventions.join(', '),
          'criterios_de_alta': record
                  .postAnesthesiaRecovery.dischargeCriteria.isEmpty
              ? 'Não registrados'
              : record.postAnesthesiaRecovery.dischargeCriteria.join(', '),
          'horario_de_alta':
              _orDash(record.postAnesthesiaRecovery.dischargeTime),
          'destino_apos_recuperacao':
              _orDash(record.postAnesthesiaRecovery.destinationAfterRecovery),
          'anotacoes_de_admissao':
              _orDash(record.postAnesthesiaRecovery.admissionNotes),
          'anotacoes_de_alta':
              _orDash(record.postAnesthesiaRecovery.dischargeNotes),
        },
        'time_out': record.timeOutCompleted ? 'Concluído' : 'Pendente',
      },
      'pre_anestesico': {
        'comorbidades': record.preAnestheticAssessment.comorbidities.isEmpty ? 'Nenhuma registrada' : record.preAnestheticAssessment.comorbidities.join(', '),
        'outras_comorbidades': _orDash(record.preAnestheticAssessment.otherComorbidities),
        'capacidade_funcional_ou_reserva': _orDash(record.preAnestheticAssessment.mets),
        'exame_fisico': _orDash(record.preAnestheticAssessment.physicalExam),
        'prioridade_do_caso': _orDash(record.preAnestheticAssessment.surgeryPriority),
        'plano_anestesico': _orDash(record.preAnestheticAssessment.anestheticPlan),
        'outros_detalhes_do_plano': _orDash(record.preAnestheticAssessment.otherAnestheticPlan),
        'planejamento_pos_operatorio': record.preAnestheticAssessment.postoperativePlanningItems.isEmpty ? 'Não registrado' : record.preAnestheticAssessment.postoperativePlanningItems.join(', '),
        'outras_medidas_pos_operatorias': _orDash(record.preAnestheticAssessment.otherPostoperativePlanning),
        'anotacoes_livres': _orDash(record.preAnestheticAssessment.planningNotes),
        'jejum': {
          'solidos_formula_refeicao': _orDash(record.preAnestheticAssessment.fastingSolids),
          'liquidos_claros': _orDash(record.preAnestheticAssessment.fastingLiquids),
          'leite_materno': _orDash(record.preAnestheticAssessment.fastingBreastMilk),
          'observacoes': _orDash(record.preAnestheticAssessment.fastingNotes),
        },
        'exames_complementares': record.preAnestheticAssessment.complementaryExamItems.isEmpty ? 'Nenhum registrado' : record.preAnestheticAssessment.complementaryExamItems.join(', '),
        'outros_exames': _orDash(record.preAnestheticAssessment.complementaryExams),
      },
      'responsavel': {
        'anestesiologistas': anesthesiologists.isEmpty
            ? 'Não informados'
            : anesthesiologists,
      },
      'gerado_em': DateTime.now().toIso8601String(),
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
      ['Consentimento', _orDash(record.patient.informedConsentStatus)],
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

  pw.Widget _hemodynamicChart(AnesthesiaRecord record) {
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
            'Gráfico hemodinâmico',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            height: 240,
            width: double.infinity,
            child: pw.SvgImage(svg: _hemodynamicChartSvg(record)),
          ),
        ],
      ),
    );
  }

  String _hemodynamicChartSvg(AnesthesiaRecord record) {
    const width = 960.0;
    const height = 240.0;
    const left = 76.0;
    const right = 24.0;
    const top = 24.0;
    const bottom = 28.0;
    const spo2Height = 54.0;
    const gap = 14.0;
    final hemoTop = top + spo2Height + gap;
    final hemoHeight = height - hemoTop - bottom;
    final chartWidth = width - left - right;
    final maxTime = _hemodynamicDisplayMaxTime(record);

    double xForTime(double time) => left + (time / maxTime) * chartWidth;
    double yForSpo2(double value) {
      final clamped = value.clamp(70, 100);
      return top + spo2Height - ((clamped - 70) / 30) * spo2Height;
    }

    double yForHemo(double value) {
      final clamped = value.clamp(0, 200);
      return hemoTop + hemoHeight - (clamped / 200) * hemoHeight;
    }

    String pathFor(List<Map<String, double>> data, double Function(double) yMap) {
      if (data.isEmpty) return '';
      final sorted = [...data]..sort((a, b) => a['time']!.compareTo(b['time']!));
      final buffer = StringBuffer();
      for (var index = 0; index < sorted.length; index++) {
        final x = xForTime(sorted[index]['time']!);
        final y = yMap(sorted[index]['value']!);
        buffer.write('${index == 0 ? 'M' : 'L'} ${x.toStringAsFixed(1)} ${y.toStringAsFixed(1)} ');
      }
      return buffer.toString().trim();
    }

    String escapeSvgText(String value) {
      return value
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&apos;');
    }

    String symbolMarkupFor(
      String type,
      List<Map<String, double>> data,
      double Function(double) yMap,
      String color,
    ) {
      if (data.isEmpty) return '';
      final sorted = [...data]..sort((a, b) => a['time']!.compareTo(b['time']!));
      final buffer = StringBuffer();
      for (final point in sorted) {
        final x = xForTime(point['time']!);
        final y = yMap(point['value']!);
        final valueLabel = point['value']!.round().toString();
        final xText = x.toStringAsFixed(1);
        final yText = y.toStringAsFixed(1);
        final labelDx = switch (type) {
          'PAS' => 12.0,
          'PAD' => 12.0,
          'FC' => 10.0,
          'PAM' => 12.0,
          'SpO2' => 16.0,
          'PAI' => 16.0,
          _ => 10.0,
        };
        final labelDy = switch (type) {
          'PAS' => -10.0,
          'PAD' => 14.0,
          'FC' => -10.0,
          'PAM' => -12.0,
          'SpO2' => -8.0,
          'PAI' => -16.0,
          _ => -10.0,
        };
        switch (type) {
          case 'PAS':
            buffer.writeln(
              "<path d='M ${(x - 9).toStringAsFixed(1)} ${(y - 8).toStringAsFixed(1)} L $xText ${(y + 10).toStringAsFixed(1)} L ${(x + 9).toStringAsFixed(1)} ${(y - 8).toStringAsFixed(1)} Z' fill='none' stroke='$color' stroke-width='2.6' stroke-linejoin='round' />",
            );
            break;
          case 'PAD':
            buffer.writeln(
              "<path d='M ${(x - 9).toStringAsFixed(1)} ${(y + 8).toStringAsFixed(1)} L $xText ${(y - 10).toStringAsFixed(1)} L ${(x + 9).toStringAsFixed(1)} ${(y + 8).toStringAsFixed(1)} Z' fill='none' stroke='$color' stroke-width='2.6' stroke-linejoin='round' />",
            );
            break;
          case 'FC':
            buffer.writeln(
              "<circle cx='$xText' cy='$yText' r='6.5' fill='$color' stroke='$color' stroke-width='2.2' />",
            );
            break;
          case 'PAM':
            buffer.writeln(
              "<text x='$xText' y='${(y + 5).toStringAsFixed(1)}' text-anchor='middle' font-size='16' font-weight='700' fill='$color'>M</text>",
            );
            break;
          case 'SpO2':
            buffer.writeln(
              "<text x='$xText' y='${(y + 4).toStringAsFixed(1)}' text-anchor='middle' font-size='11' font-weight='700' fill='$color'>Sat</text>",
            );
            break;
          case 'PAI':
            buffer.writeln(
              "<circle cx='$xText' cy='$yText' r='13' fill='$color' fill-opacity='0.12' stroke='$color' stroke-width='2.2' />",
            );
            buffer.writeln(
              "<text x='$xText' y='${(y + 4).toStringAsFixed(1)}' text-anchor='middle' font-size='11' font-weight='700' fill='$color'>PAI</text>",
            );
            break;
        }
        buffer.writeln(
          "<text x='${(x + labelDx).toStringAsFixed(1)}' y='${(y + labelDy).toStringAsFixed(1)}' font-size='10' font-weight='700' fill='$color'>$valueLabel</text>",
        );
      }
      return buffer.toString();
    }

    final pointsByType = <String, List<Map<String, double>>>{};
    for (final point in record.hemodynamicPoints) {
      pointsByType.putIfAbsent(point.type, () => []);
      pointsByType[point.type]!.add({'time': point.time, 'value': point.value});
    }

    final pas = pointsByType['PAS'] ?? const [];
    final pad = pointsByType['PAD'] ?? const [];
    final pam = <Map<String, double>>[];
    final usedPad = <int>{};
    for (final pasPoint in pas) {
      var bestIndex = -1;
      var bestDelta = double.infinity;
      for (var index = 0; index < pad.length; index++) {
        if (usedPad.contains(index)) continue;
        final delta = (pad[index]['time']! - pasPoint['time']!).abs();
        if (delta <= 1 && delta < bestDelta) {
          bestDelta = delta;
          bestIndex = index;
        }
      }
      if (bestIndex != -1) {
        usedPad.add(bestIndex);
        pam.add({
          'time': pasPoint['time']!,
          'value': (pasPoint['value']! + (2 * pad[bestIndex]['value']!)) / 3,
        });
      }
    }

    final grid = StringBuffer();
    for (var minute = 0.0; minute <= maxTime; minute += 15) {
      final x = xForTime(minute);
      grid.writeln(
        "<line x1='${x.toStringAsFixed(1)}' y1='$top' x2='${x.toStringAsFixed(1)}' y2='${(height - bottom).toStringAsFixed(1)}' stroke='${minute % 60 == 0 ? '#c9d8e8' : '#e6eef7'}' stroke-width='1' />",
      );
    }
    for (var value = 70; value <= 100; value += 10) {
      final y = yForSpo2(value.toDouble());
      grid.writeln(
        "<line x1='$left' y1='${y.toStringAsFixed(1)}' x2='${(width - right).toStringAsFixed(1)}' y2='${y.toStringAsFixed(1)}' stroke='#e7eef6' stroke-width='1' />",
      );
    }
    for (var value = 0; value <= 200; value += 20) {
      final y = yForHemo(value.toDouble());
      grid.writeln(
        "<line x1='$left' y1='${y.toStringAsFixed(1)}' x2='${(width - right).toStringAsFixed(1)}' y2='${y.toStringAsFixed(1)}' stroke='#e7eef6' stroke-width='1' />",
      );
    }

    final markers = StringBuffer();
    for (final marker in record.hemodynamicMarkers) {
      final x = xForTime(marker.time);
      final color = marker.label == 'Início da anestesia' ? '#2b76d2' : '#169653';
      final label = escapeSvgText(
        marker.clockTime.trim().isEmpty
            ? marker.label
            : '${marker.label} ${marker.clockTime}',
      );
      markers.writeln(
        "<line x1='${x.toStringAsFixed(1)}' y1='$top' x2='${x.toStringAsFixed(1)}' y2='${(height - bottom).toStringAsFixed(1)}' stroke='$color' stroke-width='1.2' />",
      );
      markers.writeln(
        "<text x='${(x + (x < 130 ? 34 : 4)).toStringAsFixed(1)}' y='14' font-size='10' font-weight='700' fill='$color'>$label</text>",
      );
    }

    String axisLabels() {
      final buffer = StringBuffer();
      for (var minute = 0.0; minute <= maxTime; minute += 60) {
        final x = xForTime(minute);
        final hour = (minute / 60).floor().toString().padLeft(2, '0');
        buffer.writeln(
          "<text x='${x.toStringAsFixed(1)}' y='${(height - 8).toStringAsFixed(1)}' font-size='10' fill='#7a8ea4'>${hour}h</text>",
        );
      }
      for (var value = 70; value <= 100; value += 10) {
        final y = yForSpo2(value.toDouble());
        buffer.writeln(
          "<text x='10' y='${(y + 4).toStringAsFixed(1)}' font-size='10' font-weight='700' fill='#16a96b'>$value</text>",
        );
      }
      for (var value = 0; value <= 200; value += 10) {
        final y = yForHemo(value.toDouble());
        buffer.writeln(
          "<text x='10' y='${(y + 4).toStringAsFixed(1)}' font-size='10' font-weight='700' fill='#5f7896'>$value</text>",
        );
      }
      buffer.writeln(
        "<text x='44' y='18' font-size='11' font-weight='700' fill='#16a96b'>SpO₂</text>",
      );
      return buffer.toString();
    }

    return """
<svg xmlns='http://www.w3.org/2000/svg' width='$width' height='$height' viewBox='0 0 $width $height'>
  <rect x='0' y='0' width='$width' height='$height' fill='white'/>
  ${grid.toString()}
  <line x1='$left' y1='$top' x2='$left' y2='${(height - bottom).toStringAsFixed(1)}' stroke='#8ea5bf' stroke-width='1.5' />
  <line x1='$left' y1='${(top + spo2Height + 7).toStringAsFixed(1)}' x2='${(width - right).toStringAsFixed(1)}' y2='${(top + spo2Height + 7).toStringAsFixed(1)}' stroke='#c8d6e5' stroke-width='1.2' />
  ${markers.toString()}
  <path d='${pathFor(pas, yForHemo)}' fill='none' stroke='#365fd5' stroke-width='2.5'/>
  <path d='${pathFor(pad, yForHemo)}' fill='none' stroke='#6b8df2' stroke-width='2.5'/>
  <path d='${pathFor(pam, yForHemo)}' fill='none' stroke='#2747b8' stroke-width='2.5'/>
  <path d='${pathFor(pointsByType['FC'] ?? const [], yForHemo)}' fill='none' stroke='#ea5455' stroke-width='2.5'/>
  <path d='${pathFor(pointsByType['SpO2'] ?? const [], yForSpo2)}' fill='none' stroke='#16a96b' stroke-width='2.5'/>
  <path d='${pathFor(pointsByType['PAI'] ?? const [], yForHemo)}' fill='none' stroke='#5b6b7a' stroke-width='2.5'/>
  ${symbolMarkupFor('PAS', pas, yForHemo, '#365fd5')}
  ${symbolMarkupFor('PAD', pad, yForHemo, '#6b8df2')}
  ${symbolMarkupFor('PAM', pam, yForHemo, '#2747b8')}
  ${symbolMarkupFor('FC', pointsByType['FC'] ?? const [], yForHemo, '#ea5455')}
  ${symbolMarkupFor('SpO2', pointsByType['SpO2'] ?? const [], yForSpo2, '#16a96b')}
  ${symbolMarkupFor('PAI', pointsByType['PAI'] ?? const [], yForHemo, '#5b6b7a')}
  ${axisLabels()}
</svg>
""";
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

  static double _hemodynamicDisplayMaxTime(AnesthesiaRecord record) {
    final pointMax = record.hemodynamicPoints.isEmpty
        ? 0.0
        : record.hemodynamicPoints
            .map((item) => item.time)
            .reduce((a, b) => a > b ? a : b);
    final markerMax = record.hemodynamicMarkers.isEmpty
        ? 0.0
        : record.hemodynamicMarkers
            .map((item) => item.time)
            .reduce((a, b) => a > b ? a : b);
    final maxValue = pointMax > markerMax ? pointMax : markerMax;
    if (maxValue <= 180) return 180;
    return (maxValue / 15).ceil() * 15.0;
  }
}
