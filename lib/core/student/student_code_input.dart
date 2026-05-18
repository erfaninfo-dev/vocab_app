import 'package:flutter/services.dart';

const int kStudentCodeLength = 5;

final List<TextInputFormatter> studentCodeInputFormatters = [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(kStudentCodeLength),
];

bool isValidStudentCode(String? raw) {
  final s = raw?.trim() ?? '';
  return RegExp(r'^\d{5}$').hasMatch(s);
}
