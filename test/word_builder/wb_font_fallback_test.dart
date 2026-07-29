import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/theme/word_builder_tokens.dart';

void main() {
  testWidgets('Lexend + Vazirmatn fallback paints Latin and Persian together',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Word واژه',
              textDirection: TextDirection.ltr,
              style: WbTokens.textStyle(
                fontSize: WbTokens.tLg,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.text('Word واژه'));
    expect(text.style?.fontFamily, WbTokens.fontFamily);
    expect(text.style?.fontFamilyFallback, WbTokens.fontFamilyFallback);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/wb_lexend_vazirmatn_fallback.png'),
    );
  });
}
