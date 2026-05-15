import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class TermPaymentStatusChip extends StatelessWidget {
  const TermPaymentStatusChip({
    super.key,
    required this.isPaid,
    required this.l10n,
    this.onTap,
  });

  final bool isPaid;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  static const Color _paidBg = Color(0xFFE8F5E9);
  static const Color _paidFg = Color(0xFF1B5E20);
  static const Color _unpaidBg = Color(0xFFFFF3E0);
  static const Color _unpaidFg = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    final bg = isPaid ? _paidBg : _unpaidBg;
    final fg = isPaid ? _paidFg : _unpaidFg;
    final label =
        isPaid ? l10n.classTermPaymentPaid : l10n.classTermPaymentUnpaid;

    final inner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPaid) ...[
            Icon(Icons.check_rounded, size: 17, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1.1,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return inner;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: inner,
      ),
    );
  }
}
