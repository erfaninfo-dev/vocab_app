import 'grammar_result.dart';
import 'grammar_session_item.dart';

class GrammarResultDetail {
  const GrammarResultDetail({
    required this.result,
    required this.items,
  });

  final GrammarResult result;
  final List<GrammarSessionItem> items;

  factory GrammarResultDetail.fromApiJson(Map<String, dynamic> json) {
    final r = json['result'] as Map<String, dynamic>;
    final session = r['session'];
    List<GrammarSessionItem> items = [];
    if (session is Map<String, dynamic>) {
      final raw = session['items'];
      if (raw is List<dynamic>) {
        items = raw
            .map((e) => GrammarSessionItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return GrammarResultDetail(
      result: GrammarResult.fromJson(r),
      items: items,
    );
  }
}
