/// A grammar topic's attached educational PDF, as returned by
/// `GET /grammar_topic_pdfs.php`. Keyed by topic name since grammar topics
/// have no numeric id (they're a derived grouping of `grammar_questions.topic`).
class GrammarTopicPdf {
  const GrammarTopicPdf({required this.topic, required this.pdfUrl});

  final String topic;
  final String pdfUrl;

  factory GrammarTopicPdf.fromJson(Map<String, dynamic> json) {
    return GrammarTopicPdf(
      topic: (json['topic'] ?? '').toString(),
      pdfUrl: (json['pdf_url'] ?? '').toString(),
    );
  }
}
