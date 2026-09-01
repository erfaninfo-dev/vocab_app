import 'package:flutter/material.dart';

import '../../../data/models/unit_model.dart';
import '../../../l10n/app_localizations.dart';
import 'idioms_unit_progress.dart';
import 'idioms_units_constants.dart';

class IdiomsUnitCard extends StatelessWidget {
  const IdiomsUnitCard({
    super.key,
    required this.l10n,
    required this.unitInfo,
    required this.progress,
    required this.isLoading,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final UnitInfo unitInfo;
  final IdiomsUnitProgress progress;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = idiomsThemeForUnit(unitInfo.unit);
    final title = idiomsUnitDisplayTitle(unitInfo.unitDetails);
    final assetPath = idiomsUnitAssetPath(
      unitInfo.unit,
      unitDetails: unitInfo.unitDetails,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;
        final scale = idiomsCardScale(side);
        double px(double design) => design * scale;

        final borderRadius = BorderRadius.circular(px(22));
        final imageSlotW = side * kIdiomsImageSlotWidthFactor;
        final imageSlotH = cardHeight * kIdiomsImageSlotHeightFactor;
        final imageExtraScale = idiomsImageSlotScale(assetPath);
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
                        ? 0.22
                        : 0.12,
                  ),
                  blurRadius: px(18),
                  offset: Offset(0, px(8)),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Material(
                color: idiomsUnitCardSurface(context, theme),
                child: InkWell(
                  onTap: isLoading ? null : onTap,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned(
                        right: px(8),
                        bottom: px(38),
                        width: imageSlotW,
                        height: imageSlotH,
                        child: _UnitIllustration(
                          assetPath: assetPath,
                          extraScale: imageExtraScale,
                        ),
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
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: px(9),
                                  vertical: px(4),
                                ),
                                decoration: BoxDecoration(
                                  color: theme.accent.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(px(20)),
                                ),
                                child: Text(
                                  l10n.unitLabel(unitInfo.unit),
                                  style: TextStyle(
                                    color: theme.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              SizedBox(height: px(6)),
                              Padding(
                                padding: EdgeInsets.only(left: px(9)),
                                child: SizedBox(
                                  width: side - px(12) * 2 - px(9),
                                  child: Text(
                                    title.isEmpty
                                        ? l10n.unitLabel(unitInfo.unit)
                                        : title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      height: 1.15,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.88),
                                    ),
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
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            px(4),
                                          ),
                                          child: LinearProgressIndicator(
                                            value: progress.fraction,
                                            minHeight: px(3),
                                            backgroundColor: theme.accent
                                                .withValues(alpha: 0.18),
                                            color: theme.accent,
                                          ),
                                        ),
                                        SizedBox(height: px(4)),
                                        Text(
                                          '${progress.done}/${progress.total}',
                                          style: TextStyle(
                                            color: theme.accent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: px(8)),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: theme.accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: px(1.5),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.accent.withValues(
                                            alpha: 0.35,
                                          ),
                                          blurRadius: px(10),
                                          offset: Offset(0, px(4)),
                                        ),
                                      ],
                                    ),
                                    child: SizedBox(
                                      width: px(34),
                                      height: px(34),
                                      child: isLoading
                                          ? Padding(
                                              padding: EdgeInsets.all(px(8)),
                                              child: CircularProgressIndicator(
                                                strokeWidth: px(2.2),
                                                color: Colors.white.withValues(
                                                  alpha: 0.95,
                                                ),
                                              ),
                                            )
                                          : Icon(
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

class _UnitIllustration extends StatelessWidget {
  const _UnitIllustration({
    required this.assetPath,
    required this.extraScale,
  });

  final String? assetPath;
  final double extraScale;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path == null || path.isEmpty) return const SizedBox.shrink();

    return ClipRect(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Transform.scale(
          scale: extraScale,
          alignment: Alignment.bottomRight,
          child: Image.asset(
            path,
            fit: BoxFit.contain,
            alignment: Alignment.bottomRight,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
