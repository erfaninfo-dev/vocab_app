class SpeakingTopic {
  const SpeakingTopic({
    required this.id,
    required this.title,
    required this.questionCount,
    required this.sortOrder,
  });

  final int id;
  final String title;
  final int questionCount;
  final int sortOrder;

  factory SpeakingTopic.fromJson(Map<String, dynamic> json) {
    return SpeakingTopic(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
