import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_provider.dart';
import '../data/models/section_info.dart';
import 'api_providers.dart';
import 'api_remote_data_epoch.dart';

/// Wrong answers tracked on the server (requires auth). Empty when logged out.
final vocabQuizWrongsProvider =
    FutureProvider.family<List<({int unit, String wordKey})>, ({int bookId, int? unit})>((
  ref,
  arg,
) async {
  ref.watch(apiRemoteDataEpochProvider);
  final session = await ref.watch(authProvider.future);
  if (session == null || session.token.isEmpty) return [];
  return ref.read(apiServiceProvider).fetchVocabQuizWrongs(
        arg.bookId,
        unit: arg.unit,
      );
});

typedef BookQuizUnitsKey = ({int bookId, List<int> units});

/// Sections for each selected unit that has them (from sections.php).
final bookQuizSectionsForUnitsProvider =
    FutureProvider.family<Map<int, List<SectionInfo>>, BookQuizUnitsKey>((
  ref,
  key,
) async {
  if (key.units.isEmpty) return {};
  final api = ref.read(apiServiceProvider);
  final out = <int, List<SectionInfo>>{};
  await Future.wait(
    key.units.map((unit) async {
      try {
        final sections = await api.fetchSections(key.bookId, unit);
        if (sections.isNotEmpty) {
          out[unit] = sections;
        }
      } catch (_) {}
    }),
  );
  return out;
});
