import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/book_asset.dart';
import '../data/models/vocab_entry.dart';
import '../data/repositories/vocabulary_repository.dart';

typedef BookUnitSection = ({String assetPath, int unit, int section});

final vocabularyRepositoryProvider =
    Provider.family<VocabularyRepository, String>((ref, assetPath) {
      return VocabularyRepository(assetPath: assetPath);
    });

/// Discovers every .xlsx / .xls file in the bundled `data/` folder
/// and returns them as [BookAsset] objects sorted by title.
final bookCatalogProvider = FutureProvider<List<BookAsset>>((ref) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final books = manifest
      .listAssets()
      .where(
        (asset) =>
            asset.startsWith('data/') &&
            (asset.endsWith('.xlsx') || asset.endsWith('.xls')),
      )
      .map((path) => BookAsset(assetPath: path))
      .toList()
    ..sort((a, b) => a.title.compareTo(b.title));

  return books;
});

final vocabularyListProvider =
    FutureProvider.family<List<VocabEntry>, String>((ref, assetPath) async {
      final repository = ref.watch(vocabularyRepositoryProvider(assetPath));
      return repository.loadEntries();
    });

final unitListProvider = Provider.family<AsyncValue<List<int>>, String>((
  ref,
  assetPath,
) {
  final data = ref.watch(vocabularyListProvider(assetPath));
  return data.whenData((entries) {
    final units = entries.map((entry) => entry.unit).toSet().toList()..sort();
    return units;
  });
});

final wordsByUnitSectionProvider =
    Provider.family<AsyncValue<List<VocabEntry>>, BookUnitSection>((ref, arg) {
      final data = ref.watch(vocabularyListProvider(arg.assetPath));
      return data.whenData(
        (entries) => entries
            .where(
              (entry) => entry.unit == arg.unit && entry.section == arg.section,
            )
            .toList(),
      );
    });
