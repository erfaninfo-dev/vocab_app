class GrammarTopicSummary {
  const GrammarTopicSummary({
    required this.topic,
    required this.questionCount,
    this.topicCreatedAt,
    this.isNew = false,
  });

  final String topic;
  final int questionCount;
  final DateTime? topicCreatedAt;
  final bool isNew;

  factory GrammarTopicSummary.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['topic_created_at']?.toString();
    return GrammarTopicSummary(
      topic: json['topic'] as String? ?? '',
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
      topicCreatedAt: rawCreatedAt == null || rawCreatedAt.isEmpty
          ? null
          : DateTime.tryParse(rawCreatedAt.replaceFirst(' ', 'T')),
      isNew:
          json['is_new'] == true ||
          json['is_new'] == 1 ||
          json['is_new'] == '1',
    );
  }
}
