import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_provider.dart';
import 'api_providers.dart';

/// Wrong answers tracked on the server (requires auth). Empty when logged out.
final vocabQuizWrongsProvider =
    FutureProvider.family<List<({int unit, String wordKey})>, ({int bookId, int? unit})>((
  ref,
  arg,
) async {
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null || session.token.isEmpty) return [];
  return ref.read(apiServiceProvider).fetchVocabQuizWrongs(
        arg.bookId,
        unit: arg.unit,
      );
});
