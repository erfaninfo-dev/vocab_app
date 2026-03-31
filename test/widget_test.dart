import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ielts_vocab_app/data/models/book_asset.dart';
import 'package:ielts_vocab_app/data/models/vocab_entry.dart';
import 'package:ielts_vocab_app/data/repositories/vocabulary_repository.dart';
import 'package:ielts_vocab_app/domain/vocabulary_providers.dart';
import 'package:ielts_vocab_app/main.dart';

const _testAssetPath = 'assets/data/sample_words.json';

void main() {
  testWidgets('shows book card on home screen after splash',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookCatalogProvider.overrideWith(
            (ref) async => [BookAsset(assetPath: _testAssetPath)],
          ),
          vocabularyRepositoryProvider(_testAssetPath).overrideWithValue(
            _FakeVocabularyRepository(),
          ),
        ],
        child: const IeltsVocabApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1400));

    // BookAsset(assetPath: 'assets/data/sample_words.json').title == 'Sample Words'
    expect(find.text('Sample Words'), findsOneWidget);
  });

  testWidgets('navigates book card → units screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookCatalogProvider.overrideWith(
            (ref) async => [BookAsset(assetPath: _testAssetPath)],
          ),
          vocabularyRepositoryProvider(_testAssetPath).overrideWithValue(
            _FakeVocabularyRepository(),
          ),
        ],
        child: const IeltsVocabApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1400));

    await tester.tap(find.text('Sample Words'));
    await tester.pumpAndSettle();

    expect(find.text('Unit 1'), findsOneWidget);
    expect(find.text('Unit 2'), findsOneWidget);
  });

  testWidgets('navigates unit → section list', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookCatalogProvider.overrideWith(
            (ref) async => [BookAsset(assetPath: _testAssetPath)],
          ),
          vocabularyRepositoryProvider(_testAssetPath).overrideWithValue(
            _FakeVocabularyRepository(),
          ),
        ],
        child: const IeltsVocabApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1400));

    await tester.tap(find.text('Sample Words'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unit 1'));
    await tester.pumpAndSettle();

    expect(find.text('Section 1'), findsOneWidget);
    expect(find.text('Section 2'), findsOneWidget);
    expect(find.text('Section 3'), findsOneWidget);
  });
}

class _FakeVocabularyRepository extends VocabularyRepository {
  _FakeVocabularyRepository() : super(assetPath: _testAssetPath);

  @override
  Future<List<VocabEntry>> loadEntries() async {
    return const [
      VocabEntry(
        bookId: _testAssetPath,
        word: 'accumulate',
        type: 'v',
        meaningEn: 'collect over time',
        meaningFa: 'جمع كردن',
        exampleEn: 'Accumulate words daily.',
        exampleFa: 'هر روز لغت جمع كن.',
        unit: 1,
        section: 1,
      ),
      VocabEntry(
        bookId: _testAssetPath,
        word: 'adapt',
        type: 'v',
        meaningEn: 'adjust',
        meaningFa: 'سازگار شدن',
        exampleEn: 'Adapt to context.',
        exampleFa: 'با بافت سازگار شو.',
        unit: 1,
        section: 2,
      ),
      VocabEntry(
        bookId: _testAssetPath,
        word: 'array',
        type: 'n',
        meaningEn: 'collection',
        meaningFa: 'مجموعه',
        exampleEn: 'An array of options.',
        exampleFa: 'مجموعه‌اي از گزينه‌ها.',
        unit: 2,
        section: 1,
      ),
    ];
  }
}
