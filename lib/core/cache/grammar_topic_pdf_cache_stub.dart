/// No-op on platforms without `dart:io` (e.g. web).
class GrammarTopicPdfCache {
  GrammarTopicPdfCache._();
  static final GrammarTopicPdfCache instance = GrammarTopicPdfCache._();

  Future<void> init() async {}

  Future<String?> ensureCached({
    required String pdfUrl,
    String? contentVersion,
  }) async =>
      null;

  Future<void> invalidate({
    required String pdfUrl,
    String? contentVersion,
  }) async {}
}
