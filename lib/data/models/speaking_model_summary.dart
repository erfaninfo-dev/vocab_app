class SpeakingModelSummary {
  const SpeakingModelSummary({
    required this.id,
    required this.modelNumber,
    required this.title,
    required this.formula,
    required this.template,
    required this.questionCount,
  });

  final int id;
  final int modelNumber;
  final String title;
  final String formula;
  final String template;
  final int questionCount;

  factory SpeakingModelSummary.fromJson(Map<String, dynamic> json) {
    return SpeakingModelSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      modelNumber: (json['model_number'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      formula: json['formula'] as String? ?? '',
      template: json['template'] as String? ?? '',
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
    );
  }
}
