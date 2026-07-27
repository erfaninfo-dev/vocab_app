enum FlashcardDirection {
  wordToMeaning('wordToMeaning'),
  meaningToWord('meaningToWord');

  const FlashcardDirection(this.key);

  final String key;

  static FlashcardDirection fromKey(String? key) {
    return key == 'meaningToWord'
        ? FlashcardDirection.meaningToWord
        : FlashcardDirection.wordToMeaning;
  }
}
