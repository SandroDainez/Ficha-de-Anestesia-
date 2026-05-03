import 'package:anestesia_app/models/anesthesia_record.dart';
import 'package:anestesia_app/models/airway.dart';
import 'package:anestesia_app/models/fluid_balance.dart';
import 'package:anestesia_app/models/patient.dart';
import 'package:anestesia_app/services/ai_record_analysis_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = AiRecordAnalysisService();

  test('marks incomplete records as pending', () async {
    final analysis = await service.analyzeRecord(
      const AnesthesiaRecord.empty(),
    );

    expect(analysis.status, 'pendente');
    expect(analysis.isComplete, isFalse);
    expect(analysis.missingFields, contains('Identificação do paciente'));
    expect(
      analysis.recommendations,
      contains(
        'Consulta pré-anestésica não registrada. Isso deve aparecer como orientação e não como bloqueio, sobretudo em urgência/emergência; documente a justificativa quando aplicável.',
      ),
    );
  });

  test(
    'flags inconsistencies and recommendations for a partially filled record',
    () async {
      final record = AnesthesiaRecord.empty().copyWith(
        patient: const Patient(
          name: 'Joao',
          age: 50,
          weightKg: 80,
          heightMeters: 1.75,
          asa: 'II',
          allergies: ['Latex'],
          restrictions: [],
          medications: ['Metformina'],
        ),
        airway: const Airway(
          mallampati: 'II',
          cormackLehane: 'I',
          device: 'TOT',
          tubeNumber: '',
          technique: 'Laringoscopia direta',
          observation: '',
        ),
        anesthesiaTechnique: 'Geral',
        maintenanceAgents: 'Sevoflurano',
        drugs: const ['Propofol'],
        events: const ['Hipotensao'],
        fluidBalance: const FluidBalance(
          crystalloids: '3000',
          colloids: '0',
          blood: '0',
          diuresis: '300',
          bleeding: '200',
          spongeCount: '',
          otherLosses: '',
        ),
      );

      final analysis = await service.analyzeRecord(record);

      expect(analysis.status, 'pendente');
      expect(analysis.missingFields, contains('Via aérea'));
      expect(
        analysis.findings,
        contains('Tubo orotraqueal selecionado sem número definido.'),
      );
      expect(
        analysis.findings,
        contains('Balanço hídrico positivo elevado para revisão clínica.'),
      );
      expect(
        analysis.recommendations,
        contains('Confirmar alergias e restrições antes da finalização.'),
      );
      expect(
        analysis.recommendations,
        contains(
          'Checar coerência entre técnica, manutenção e drogas administradas.',
        ),
      );
    },
  );
}
