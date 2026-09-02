import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_jelly_style.dart';
import '../../l10n/app_localizations.dart';
import 'speaking_constants.dart';

class SpeakingHomeCard extends StatelessWidget {
  const SpeakingHomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppJellyCard(
        clipBehavior: Clip.antiAlias,
        onTap: () => context.push('/speaking/part1'),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kAppJellyRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kSpeakingBrandTeal.withValues(alpha: 0.22),
                        kSpeakingBrandCyan.withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -20,
                bottom: -24,
                child: Icon(
                  Icons.graphic_eq_rounded,
                  size: 120,
                  color: kSpeakingBrandTeal.withValues(alpha: 0.12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppJellyIconBubble(
                          color: kSpeakingBrandTeal,
                          size: 40,
                          child: const Icon(
                            Icons.mic_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_outward_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.speakingHomeCardTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              height: 1.15,
                              color: speakingCardTitleColor(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.speakingHomeCardSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.3,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kSpeakingBrandTeal.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.speakingPart1Badge,
                        style: const TextStyle(
                          color: kSpeakingBrandTeal,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
