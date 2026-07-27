enum FlashcardPool {
  all('all'),
  important('important'),
  favorites('favorites');

  const FlashcardPool(this.key);

  final String key;
}
