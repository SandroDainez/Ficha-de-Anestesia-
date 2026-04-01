import 'package:flutter/material.dart';

import '../models/anesthesia_record.dart';
import '../models/airway.dart';
import '../models/patient.dart';
import '../models/pre_anesthetic_assessment.dart';
import 'anesthesia_screen.dart';
import 'pre_anesthetic_screen.dart';

class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Casos de Anestesia',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
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
                        Icons.local_hospital_outlined,
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
                        'Escolha se deseja abrir a ficha anestésica diretamente ou começar pela consulta pré-anestésica. Todos os campos iniciam em branco.',
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
                            width: 300,
                            child: FilledButton.icon(
                              onPressed: () => _openAnesthesiaRecord(context),
                              icon: const Icon(Icons.assignment_outlined),
                              label: const Text('Nova ficha anestésica'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 300,
                            child: OutlinedButton.icon(
                              onPressed: () => _openPreAnesthetic(context),
                              icon: const Icon(Icons.description_outlined),
                              label: const Text('Nova consulta pré-anestésica'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Use a ficha direta para urgência / emergência, quando a avaliação pré-anestésica completa não puder ser realizada antes do procedimento.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF7A8EA5),
                          fontSize: 13,
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
      ),
    );
  }

  void _openAnesthesiaRecord(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AnesthesiaScreen(
          initialRecord: AnesthesiaRecord.empty(),
        ),
      ),
    );
  }

  Future<void> _openPreAnesthetic(BuildContext context) async {
    final result = await Navigator.of(context).push<PreAnestheticScreenResult>(
      MaterialPageRoute<PreAnestheticScreenResult>(
        builder: (_) => const PreAnestheticScreen(
          patient: Patient.empty(),
          initialAssessment: PreAnestheticAssessment.empty(),
        ),
      ),
    );

    if (!context.mounted || result == null) return;

    final record = AnesthesiaRecord.empty().copyWith(
      patient: result.patient,
      preAnestheticAssessment: result.assessment,
      airway: Airway.empty(),
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnesthesiaScreen(initialRecord: record),
      ),
    );
  }
}
