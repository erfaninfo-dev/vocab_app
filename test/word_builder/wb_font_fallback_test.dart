import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/theme/word_builder_tokens.dart';

void main() {
  test('WbTokens textStyle uses Lexend with Vazirmatn fallback', () {
    final style = WbTokens.textStyle(fontSize: 24, color: Colors.black);
    expect(style.fontFamily, WbTokens.fontFamily);
    expect(style.fontFamilyFallback, WbTokens.fontFamilyFallback);
    expect(style.fontFamilyFallback, contains('Vazirmatn'));
  });

  testWidgets('Persian sample text paints with WbTokens style', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Text(
            'سلام',
            style: WbTokens.textStyle(fontSize: 24),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('سلام'), findsOneWidget);
  });
}
