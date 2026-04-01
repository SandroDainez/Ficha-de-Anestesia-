import '../models/anesthesia_record.dart';

class RecordValidationService {
  const RecordValidationService();

  List<String> validateRequiredFields(AnesthesiaRecord record) {
    final missing = <String>[];

    if (record.patient.name.trim().isEmpty) {
      missing.add('Identificação do paciente');
    }

    if (!record.airway.isComplete) {
      missing.add('Via aérea');
    }

    if (record.anesthesiaTechnique.trim().isEmpty) {
      missing.add('Técnica anestésica');
    }

    if (record.drugs.isEmpty) {
      missing.add('Drogas e infusões');
    }

    if (record.events.isEmpty) {
      missing.add('Eventos intraoperatórios');
    }

    if (!record.fluidBalance.isComplete) {
      missing.add('Balanço hídrico');
    }

    return missing;
  }
}
