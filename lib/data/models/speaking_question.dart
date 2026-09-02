import 'speaking_topic.dart';

class SpeakingModelQuestion {
  const SpeakingModelQuestion({
    required this.id,
    required this.modelNumber,
    required this.title,
    required this.formula,
    required this.template,
  });

  final int id;
  final int modelNumber;
  final String title;
  final String formula;
  final String template;

  factory SpeakingModelQuestion.fromJson(Map<String, dynamic> json) {
    return SpeakingModelQuestion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      modelNumber: (json['model_number'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      formula: json['formula'] as String? ?? '',
      template: json['template'] as String? ?? '',
    );
  }
}

class SpeakingQuestion {
  const SpeakingQuestion({
    required this.id,
    required this.questionText,
    required this.answer,
    required this.faAnswer,
    required this.kurAnswer,
    required this.sortOrder,
    required this.model,
    this.topicId,
    this.topicTitle,
  });

  final int id;
  final String questionText;
  final String answer;
  final String faAnswer;
  final String kurAnswer;
  final int sortOrder;
  final SpeakingModelQuestion model;
  final int? topicId;
  final String? topicTitle;

  factory SpeakingQuestion.fromJson(Map<String, dynamic> json) {
    final topicJson = json['topic'] as Map<String, dynamic>?;
    return SpeakingQuestion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      questionText: json['question_text'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      faAnswer: json['fa_answer'] as String? ?? '',
      kurAnswer: json['kur_answer'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      model: SpeakingModelQuestion.fromJson(
        json['model'] as Map<String, dynamic>? ?? const {},
      ),
      topicId: (topicJson?['id'] as num?)?.toInt(),
      topicTitle: topicJson?['title'] as String?,
    );
  }
}

class SpeakingModelQuestionsResponse {
  const SpeakingModelQuestionsResponse({
    required this.model,
    required this.questions,
  });

  final SpeakingModelQuestion model;
  final List<SpeakingQuestion> questions;

  factory SpeakingModelQuestionsResponse.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? const [];
    return SpeakingModelQuestionsResponse(
      model: SpeakingModelQuestion.fromJson(
        json['model'] as Map<String, dynamic>? ?? const {},
      ),
      questions: rawQuestions
          .map((e) => SpeakingQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SpeakingTopicQuestionsResponse {
  const SpeakingTopicQuestionsResponse({
    required this.topic,
    required this.questions,
  });

  final SpeakingTopic topic;
  final List<SpeakingQuestion> questions;

  factory SpeakingTopicQuestionsResponse.fromJson(Map<String, dynamic> json) {
    final topicJson = json['topic'] as Map<String, dynamic>? ?? const {};
    final rawQuestions = json['questions'] as List<dynamic>? ?? const [];
    return SpeakingTopicQuestionsResponse(
      topic: SpeakingTopic(
        id: (topicJson['id'] as num?)?.toInt() ?? 0,
        title: topicJson['title'] as String? ?? '',
        questionCount: rawQuestions.length,
        sortOrder: 0,
      ),
      questions: rawQuestions
          .map((e) => SpeakingQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
