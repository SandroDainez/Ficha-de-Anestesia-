import '../models/anesthesia_record.dart';
import '../models/record_analysis.dart';
import 'record_validation_service.dart';

class AiRecordAnalysisService {
  const AiRecordAnalysisService({
    this.validationService = const RecordValidationService(),
  });

  final RecordValidationService validationService;

  Future<RecordAnalysis> analyzeRecord(AnesthesiaRecord record) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final missingFields = validationService.validateRequiredFields(record);
    final hasPreAnestheticData =
        record.preAnestheticAssessment.mets.trim().isNotEmpty ||
        record.preAnestheticAssessment.asaClassification.trim().isNotEmpty ||
        record.preAnestheticAssessment.comorbidities.isNotEmpty ||
        record.preAnestheticAssessment.currentMedications.isNotEmpty ||
        record.preAnestheticAssessment.allergyDescription.trim().isNotEmpty;
    final findings = <String>[];
    final recommendations = <String>[];

    if (record.airway.device == 'TOT' &&
        record.airway.tubeNumber.trim().isEmpty) {
      findings.add('Tubo orotraqueal selecionado sem número definido.');
    }

    if (record.fluidBalance.totalBalance > 1500) {
      findings.add('Balanço hídrico positivo elevado para revisão clínica.');
      recommendations.add('Revisar reposição volêmica e perdas registradas.');
    }

    if (record.fluidBalance.totalBalance < -500) {
      findings.add('Balanço hídrico negativo importante.');
      recommendations.add('Avaliar necessidade de reposição adicional.');
    }

    if (record.patient.allergies.isNotEmpty) {
      recommendations.add(
        'Confirmar alergias e restrições antes da finalização.',
      );
    }

    if (record.anesthesiaTechnique.trim().isNotEmpty) {
      recommendations.add(
        'Checar coerência entre técnica, manutenção e drogas administradas.',
      );
    }

    if (!hasPreAnestheticData) {
      recommendations.add(
        'Consulta pré-anestésica não registrada. Isso deve aparecer como orientação e não como bloqueio, sobretudo em urgência/emergência; documente a justificativa quando aplicável.',
      );
    } else {
      recommendations.add(
        'Revisar consistência entre consulta pré-anestésica e conduta intraoperatória registrada.',
      );
    }

    final summary = missingFields.isEmpty
        ? 'Ficha anestésica global consistente para revisão final, sem campos obrigatórios pendentes.'
        : 'Existem campos obrigatórios pendentes na ficha anestésica antes da finalização.';

    return RecordAnalysis(
      status: missingFields.isEmpty ? 'ok' : 'pendente',
      summary: summary,
      missingFields: missingFields,
      findings: findings,
      recommendations: recommendations,
    );
  }
}
