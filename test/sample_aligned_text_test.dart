import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/features/unit_samples/sample_aligned_text.dart';

void main() {
  test('splits Kurdish section labeled کوردی:', () {
    const raw = '''
English:
Last month, I traveled by train.
کوردی:
مانگی ڕابردوو، بە شەمەندەفەر گەشتم کرد.
''';

    final pairs = parseSampleAlignedPairs(raw);
    expect(pairs, hasLength(1));
    expect(pairs.first.en, contains('Last month'));
    expect(pairs.first.en, isNot(contains('کوردی')));
    expect(pairs.first.en, isNot(contains('مانگی')));
    expect(pairs.first.local, contains('مانگی'));
  });

  test('splits RTL colon label :کوردی', () {
    const raw = '''
English:
Hello world.
:کوردی
سڵاو جیهان.
''';

    final pairs = parseSampleAlignedPairs(raw);
    expect(pairs, hasLength(1));
    expect(pairs.first.en, 'Hello world.');
    expect(pairs.first.local, contains('سڵاو'));
  });

  test('splits Persian section labeled فارسی:', () {
    const raw = '''
English:
Train trip.
فارسی:
ماه گذشته با قطار سفر کردم.
''';

    final pairs = parseSampleAlignedPairs(raw);
    expect(pairs, hasLength(1));
    expect(pairs.first.en, contains('Train trip'));
    expect(pairs.first.local, contains('ماه گذشته'));
  });

  test('duplicate English: before کوردی: stays one bilingual pair', () {
    const raw = '''
English:
Kiss, Bow, or Shake Hands?
People greet each other in many different ways.

English:

کوردی:
ماچ، کڕنۆش، یان دەستدان؟
خەڵک بە جۆرێکی جیاواز سڵاو دەکەن.
''';

    final pairs = mergeOrphanBookPairs(parseSampleAlignedPairs(raw));
    expect(pairs, hasLength(1));
    expect(pairs.first.en, contains('Kiss, Bow'));
    expect(pairs.first.en, contains('People greet'));
    expect(pairs.first.local, contains('ماچ'));
    expect(pairs.first.local, isNot(contains('English')));
  });

  test('book pages keep EN and KU on same page when paragraph counts differ', () {
    const raw = '''
English:
First english paragraph.

Second english paragraph.

کوردی:
Single kurdish block for both paragraphs.
''';

    final pages = mergeOrphanBookPairs(parseSampleAlignedPairs(raw));
    expect(pages, hasLength(1));
    expect(pages.first.en, isNotEmpty);
    expect(pages.first.local, isNotEmpty);
  });

  test('mergeOrphanBookPairs joins split EN-only then local-only rows', () {
    const pairs = [
      SampleAlignedPair('English intro.', ''),
      SampleAlignedPair('', 'Kurdish intro.'),
    ];

    final merged = mergeOrphanBookPairs(pairs);
    expect(merged, hasLength(1));
    expect(merged.first.en, 'English intro.');
    expect(merged.first.local, 'Kurdish intro.');
  });
}
