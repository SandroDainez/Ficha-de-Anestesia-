class RecordAnalysis {
  const RecordAnalysis({
    required this.status,
    required this.summary,
    required this.missingFields,
    required this.findings,
    required this.recommendations,
  });

  final String status;
  final String summary;
  final List<String> missingFields;
  final List<String> findings;
  final List<String> recommendations;

  bool get isComplete => missingFields.isEmpty;
}
