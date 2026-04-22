import 'package:anestesia_app/models/anesthesia_case.dart';
import 'package:anestesia_app/models/anesthesia_record.dart';
import 'package:anestesia_app/models/patient.dart';
import 'package:anestesia_app/screens/patient_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filters cases by patient name ignoring case', () {
    final caseFile = AnesthesiaCase(
      id: 'case-jose',
      createdAtIso: '2026-04-22T09:00:00.000',
      updatedAtIso: '2026-04-22T09:00:00.000',
      preAnestheticDate: '22/04/2026 09:00',
      anesthesiaDate: '',
      status: AnesthesiaCaseStatus.preAnesthetic,
      record: AnesthesiaRecord.empty().copyWith(
        patient: const Patient(
          name: 'Jose da Silva',
          age: 58,
          weightKg: 76,
          heightMeters: 1.72,
          asa: 'II',
          allergies: [],
          restrictions: [],
          medications: [],
        ),
      ),
    );

    expect(caseMatchesPatientSearch(caseFile, ''), isTrue);
    expect(caseMatchesPatientSearch(caseFile, 'jose'), isTrue);
    expect(caseMatchesPatientSearch(caseFile, 'JOSE DA'), isTrue);
    expect(caseMatchesPatientSearch(caseFile, 'maria'), isFalse);
  });
}
