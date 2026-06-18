class GrammarQuestion {
  static const List<String> optionKeys = [
    'option1',
    'option2',
    'option3',
    'option4',
  ];

  const GrammarQuestion({
    required this.id,
    required this.topic,
    this.questionText,
    this.option1,
    this.option2,
    this.option3,
    this.option4,
    this.correctAnswer,
    this.orderNum,
    this.faExplanation,
    this.kurExplanation,
    this.engExplanation,
    this.grammarBookId,
    this.grammarUnitId,
  });

  /// Server PK.
  final int id;

  /// Same as DB column `content`: grammar topic name (e.g. "Present Simple").
  final String topic;

  final String? questionText;
  final String? option1;
  final String? option2;
  final String? option3;
  final String? option4;

  /// Values like `option1` … `option4` (case-insensitive when checking).
  final String? correctAnswer;
  final int? orderNum;

  final String? faExplanation;
  final String? kurExplanation;
  final String? engExplanation;
  final int? grammarBookId;
  final int? grammarUnitId;

  factory GrammarQuestion.fromJson(Map<String, dynamic> json) {
    return GrammarQuestion(
      id: (json['id'] as num).toInt(),
      topic: json['topic'] as String? ?? '',
      questionText: json['question_text'] as String?,
      option1: json['option1'] as String?,
      option2: json['option2'] as String?,
      option3: json['option3'] as String?,
      option4: json['option4'] as String?,
      correctAnswer: json['correct_answer'] as String?,
      orderNum: (json['order_num'] as num?)?.toInt(),
      faExplanation: json['fa_explanation'] as String?,
      kurExplanation: json['kur_explanation'] as String?,
      engExplanation: json['eng_explanation'] as String?,
      grammarBookId: (json['grammar_book_id'] as num?)?.toInt(),
      grammarUnitId: (json['grammar_unit_id'] as num?)?.toInt(),
    );
  }

  String? optionByKey(String key) {
    final k = key.trim().toLowerCase();
    switch (k) {
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

  /// Whether [selectedKey] (e.g. option2) matches [correct_answer].
  bool isCorrectKey(String? selectedKey) {
    final a = (correctAnswer ?? '').trim().toLowerCase();
    final b = (selectedKey ?? '').trim().toLowerCase();
    return a.isNotEmpty && a == b;
  }

  /// DB option keys that have non-empty text (option1 … option4 order).
  List<String> nonEmptyOptionKeys() {
    return optionKeys
        .where((key) => (optionByKey(key)?.trim().isNotEmpty ?? false))
        .toList(growable: false);
  }
}
