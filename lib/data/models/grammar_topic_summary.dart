class GrammarTopicSummary {
  const GrammarTopicSummary({
    required this.topic,
    required this.questionCount,
  });

  final String topic;
  final int questionCount;

  factory GrammarTopicSummary.fromJson(Map<String, dynamic> json) {
    return GrammarTopicSummary(
      topic: json['topic'] as String? ?? '',
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
    );
  }
}
