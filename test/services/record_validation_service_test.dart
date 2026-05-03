import 'package:anestesia_app/models/anesthesia_record.dart';
import 'package:anestesia_app/models/airway.dart';
import 'package:anestesia_app/models/fluid_balance.dart';
import 'package:anestesia_app/models/patient.dart';
import 'package:anestesia_app/services/record_validation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = RecordValidationService();

  test('returns missing required sections for empty record', () {
    final missing = service.validateRequiredFields(
      const AnesthesiaRecord.empty(),
    );

    expect(missing, contains('Identificação do paciente'));
    expect(missing, contains('Via aérea'));
    expect(missing, contains('Técnica anestésica'));
    expect(missing, contains('Descrição da técnica anestésica'));
    expect(missing, contains('Drogas e infusões'));
    expect(missing, contains('Balanço hídrico'));
  });

  test('accepts complete core record', () {
    final record = AnesthesiaRecord.empty().copyWith(
      patient: const Patient(
        name: 'Ana',
        age: 37,
        weightKg: 70,
        heightMeters: 1.68,
        asa: 'I',
        allergies: [],
        restrictions: [],
        medications: [],
      ),
      airway: const Airway(
        mallampati: 'I',
        cormackLehane: 'I',
        device: 'TOT',
        tubeNumber: '7.0',
        technique: 'Laringoscopia direta',
        observation: '',
      ),
      anesthesiaTechnique: 'Raqui',
      anesthesiaTechniqueDetails:
          'Raquianestesia com instalação do bloqueio e monitorização seriada.',
      neuraxialNeedles: const ['Quincke 25G'],
      drugs: const ['Midazolam'],
      fluidBalance: const FluidBalance(
        crystalloids: '1000',
        colloids: '0',
        blood: '0',
        diuresis: '200',
        bleeding: '50',
        spongeCount: '',
        otherLosses: '',
      ),
    );

    expect(service.validateRequiredFields(record), isEmpty);
  });
}
