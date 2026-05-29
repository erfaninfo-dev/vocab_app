import 'package:flutter/material.dart';

class StoryFontOption {
  const StoryFontOption({
    required this.value,
    required this.label,
    required this.sample,
  });

  final String value;
  final String label;
  final String sample;
}

const kStoryFontOptions = <StoryFontOption>[
  StoryFontOption(value: 'Default', label: 'Default', sample: 'Aa Default'),
  StoryFontOption(value: 'Calibri', label: 'Calibri', sample: 'Aa Calibri'),
  StoryFontOption(value: 'Rudaw', label: 'Rudaw', sample: 'ڕووداو کوردی'),
  StoryFontOption(value: 'Roboto', label: 'Roboto', sample: 'Aa Roboto'),
  StoryFontOption(value: 'Serif', label: 'Serif', sample: 'Aa Serif'),
  StoryFontOption(value: 'Monospace', label: 'Mono', sample: 'Aa Mono'),
];

String? storyFontFamily(String fontFamily) {
  final value = fontFamily.trim();
  if (value.isEmpty || value == 'Default') return null;
  return value;
}

String storyFontPickerValue(String fontFamily) {
  final value = fontFamily.trim();
  if (value.isEmpty) return 'Default';
  return kStoryFontOptions.any((option) => option.value == value)
      ? value
      : 'Default';
}

TextStyle storyFontPreviewStyle(StoryFontOption option) {
  return TextStyle(
    color: Colors.white,
    fontFamily: storyFontFamily(option.value),
    fontWeight: FontWeight.w800,
  );
}
