import 'package:flutter/material.dart';

import '../../../data/models/ai_chat.dart';
import '../../../l10n/app_localizations.dart';

class AiChatQuotaBar extends StatelessWidget {
  const AiChatQuotaBar({
    super.key,
    required this.quota,
  });

  final AiChatQuota quota;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final ratio = quota.usageRatio;
    final low = quota.remaining <= 2;
    final exhausted = quota.isExhausted;

    final barColor = exhausted
        ? scheme.error
        : low
        ? const Color(0xFFFF9500)
        : const Color(0xFF00C9A7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                exhausted ? Icons.hourglass_disabled_rounded : Icons.bolt_rounded,
                size: 18,
                color: barColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.aiTutorQuotaRemaining(quota.remaining, quota.limit),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: exhausted ? scheme.error : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.02, 1.0),
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
              color: barColor,
            ),
          ),
          if (exhausted) ...[
            const SizedBox(height: 8),
            Text(
              l10n.aiTutorQuotaExhausted,
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
