import 'package:flutter/material.dart';

import '../../../data/models/speaking_topic.dart';
import '../../../l10n/app_localizations.dart';
import 'speaking_constants.dart';

class SpeakingTopicCard extends StatelessWidget {
  const SpeakingTopicCard({
    super.key,
    required this.l10n,
    required this.topic,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final SpeakingTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = speakingThemeForTopic(topic.id);
    final title = topic.title.trim();
    final assetPath = speakingTopicAssetPath(topic.id, title: title);

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;
        final scale = speakingCardScale(side);
        double px(double design) => design * scale;

        final borderRadius = BorderRadius.circular(px(22));
        final imageSlotW = side * kSpeakingImageSlotWidthFactor;
        final imageSlotH = cardHeight * kSpeakingImageSlotHeightFactor;
        final textScaler = TextScaler.linear(
          MediaQuery.textScalerOf(context).scale(1) * scale,
        );

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: theme.accent.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.28
                        : 0.14,
                  ),
                  blurRadius: px(20),
                  offset: Offset(0, px(9)),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Material(
                color: speakingTopicCardSurface(context, theme),
                child: InkWell(
                  onTap: onTap,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned(
                        left: -px(18),
                        top: -px(10),
                        child: _WaveAccent(
                          color: theme.glow.withValues(alpha: 0.35),
                        ),
                      ),
                      Positioned(
                        right: px(6),
                        bottom: px(34),
                        width: imageSlotW,
                        height: imageSlotH,
                        child: _TopicIllustration(assetPath: assetPath),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            px(12),
                            px(12),
                            px(12),
                            px(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: px(30),
                                    height: px(30),
                                    decoration: BoxDecoration(
                                      color: theme.accent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.accent.withValues(
                                            alpha: 0.35,
                                          ),
                                          blurRadius: px(8),
                                          offset: Offset(0, px(3)),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.mic_rounded,
                                      color: Colors.white,
                                      size: px(16),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: px(8),
                                      vertical: px(3),
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.accent.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        px(20),
                                      ),
                                      border: Border.all(
                                        color: theme.accent.withValues(
                                          alpha: 0.28,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.speakingPart1Badge,
                                      style: TextStyle(
                                        color: theme.accent,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 8.5,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: px(8)),
                              SizedBox(
                                width: side - px(24),
                                child: Text(
                                  title.isEmpty
                                      ? l10n.speakingUntitledTopic
                                      : title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    height: 1.15,
                                    color: speakingCardTitleColor(context),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          size: px(14),
                                          color: theme.accent.withValues(
                                            alpha: 0.75,
                                          ),
                                        ),
                                        SizedBox(height: px(4)),
                                        Text(
                                          l10n.speakingTopicQuestionCount(
                                            topic.questionCount,
                                          ),
                                          style: TextStyle(
                                            color: theme.accent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 9.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.accent,
                                          theme.glow.withValues(alpha: 0.9),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: px(1.5),
                                      ),
                                    ),
                                    child: SizedBox(
                                      width: px(34),
                                      height: px(34),
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: px(18),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveAccent extends StatelessWidget {
  const _WaveAccent({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 72),
      painter: _WavePainter(color: color),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.2,
        size.width * 0.5,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.82,
        size.width,
        size.height * 0.42,
      );
    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final path2 = Path()
      ..moveTo(8, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.38,
        size.width * 0.62,
        size.height * 0.68,
      );
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _TopicIllustration extends StatelessWidget {
  const _TopicIllustration({required this.assetPath});

  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path == null || path.isEmpty) return const SizedBox.shrink();

    return ClipRect(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Image.asset(
          path,
          fit: BoxFit.contain,
          alignment: Alignment.bottomRight,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
