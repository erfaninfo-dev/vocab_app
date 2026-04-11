/// One question snapshot from a saved grammar session (server `session_json`).
class GrammarSessionItem {
  const GrammarSessionItem({
    required this.questionId,
    required this.topic,
    this.questionText,
    this.option1,
    this.option2,
    this.option3,
    this.option4,
    this.correctAnswer,
    this.selectedAnswer,
    required this.isCorrect,
    this.faExplanation,
    this.kurExplanation,
    this.engExplanation,
  });

  final int questionId;
  final String topic;
  final String? questionText;
  final String? option1;
  final String? option2;
  final String? option3;
  final String? option4;
  final String? correctAnswer;
  final String? selectedAnswer;
  final bool isCorrect;

  final String? faExplanation;
  final String? kurExplanation;
  final String? engExplanation;

  String? optionLabel(String key) {
    switch (key.trim().toLowerCase()) {
      case 'option1':
        return option1;
      case 'option2':
        return option2;
      case 'option3':
        return option3;
      case 'option4':
        return option4;
      default:
        return null;
    }
  }

  factory GrammarSessionItem.fromJson(Map<String, dynamic> json) {
    return GrammarSessionItem(
      questionId: (json['question_id'] as num).toInt(),
      topic: (json['topic'] as String?) ?? '',
      questionText: json['question_text'] as String?,
      option1: json['option1'] as String?,
      option2: json['option2'] as String?,
      option3: json['option3'] as String?,
      option4: json['option4'] as String?,
      correctAnswer: json['correct_answer'] as String?,
      selectedAnswer: json['selected_answer'] as String?,
      isCorrect: json['is_correct'] == true,
      faExplanation: json['fa_explanation'] as String?,
      kurExplanation: json['kur_explanation'] as String?,
      engExplanation: json['eng_explanation'] as String?,
    );
  }
}
