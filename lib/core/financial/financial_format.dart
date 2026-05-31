import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

abstract final class FinancialFormat {
  static String formatAmount(
    double amount,
    String currencyCode,
    String localeName,
    AppLocalizations l10n,
  ) {
    final formatter = NumberFormat.decimalPattern(localeName);
    final formatted = formatter.format(amount.round());
    final unit = currencyLabel(currencyCode, l10n);
    return '$formatted $unit';
  }

  static String currencyLabel(String currencyCode, AppLocalizations l10n) {
    switch (currencyCode.toUpperCase()) {
      case 'IRR':
        return l10n.financialCurrencyIrr;
      case 'USD':
        return l10n.financialCurrencyUsd;
      default:
        return currencyCode;
    }
  }

  static String compactAmount(double amount, String localeName) {
    final formatter = NumberFormat.compact(locale: localeName);
    return formatter.format(amount.round());
  }
}

abstract final class FinancialColors {
  static const receivedFg = Color(0xFF1B5E20);
  static const receivedBg = Color(0xFFE8F5E9);
  static const unpaidFg = Color(0xFFE65100);
  static const unpaidBg = Color(0xFFFFF3E0);
}
