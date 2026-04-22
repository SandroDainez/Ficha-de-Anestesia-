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

    if (record.anesthesiaTechniqueDetails.trim().isEmpty) {
      missing.add('Descrição da técnica anestésica');
    }

    final technique = record.anesthesiaTechnique.toLowerCase();
    if ((technique.contains('raqui') || technique.contains('peridural')) &&
        record.neuraxialNeedles.isEmpty) {
      missing.add('Agulhas neuraxiais');
    }

    if (record.drugs.isEmpty) {
      missing.add('Drogas e infusões');
    }

    if (!record.fluidBalance.isComplete) {
      missing.add('Balanço hídrico');
    }

    return missing;
  }
}
