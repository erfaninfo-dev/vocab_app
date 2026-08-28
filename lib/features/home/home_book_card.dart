import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_jelly_style.dart';
import '../../data/models/book_model.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import 'book_pdf_actions.dart';

/// Book tile used on home and series-books screens (same layout).
class HomeBookCard extends ConsumerWidget {
  const HomeBookCard({
    super.key,
    required this.book,
    required this.index,
    required this.onTap,
  });

  final Book book;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final unitsValue = ref.watch(apiUnitsProvider(book.id));
    final bookPdfs =
        ref.watch(apiBookPdfsProvider).valueOrNull?[book.id] ?? const [];
    final hasStudyPdfs = bookPdfs.isNotEmpty;
    final isSoon = unitsValue.maybeWhen(
      data: (units) => units.isEmpty,
      orElse: () => false,
    );
    final accents = homeBookCardAccents(index);
    final locale = Localizations.localeOf(context);
    final rtlUnitLine =
        locale.languageCode == 'fa' || locale.languageCode == 'ckb';

    return AppJellyCard(
      clipBehavior: Clip.antiAlias,
      onTap: isSoon ? null : onTap,
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
                    colors: isSoon
                        ? [
                            accents.first.withValues(alpha: 0.18),
                            accents.last.withValues(alpha: 0.11),
                          ]
                        : [
                            accents.first.withValues(alpha: 0.18),
                            accents.last.withValues(alpha: 0.08),
                          ],
                  ),
                  border: isSoon
                      ? Border.all(color: accents.first.withValues(alpha: 0.26))
                      : null,
                ),
              ),
            ),
            Stack(
              children: [
                if (isSoon)
                  Positioned(
                    right: -24,
                    bottom: -28,
                    child: Icon(
                      Icons.hourglass_empty_rounded,
                      size: 112,
                      color: accents.first.withValues(alpha: 0.13),
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
                            color: accents.first,
                            size: 40,
                            child: Icon(
                              isSoon
                                  ? Icons.hourglass_empty_rounded
                                  : Icons.auto_stories_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const Spacer(),
                          if (isSoon)
                            const SizedBox(width: 36)
                          else
                            Icon(
                              Icons.arrow_outward_rounded,
                              color: scheme.onSurfaceVariant,
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: isSoon
                                  ? scheme.onSurface.withValues(alpha: 0.90)
                                  : null,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                      ),
                      if (isSoon) ...[
                        const SizedBox(height: 5),
                        Text(
                          'New lessons are coming soon',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.82,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],

                      const Spacer(),

                      if (hasStudyPdfs && !isSoon) ...[
                        Align(
                          alignment: rtlUnitLine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () => openBookStudyPdfs(
                              context: context,
                              bookTitle: book.title,
                              pdfs: bookPdfs,
                              accent: accents.first,
                            ),
                            icon: Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 18,
                              color: accents.first,
                            ),
                            label: Text(l10n.bookStudyPdfOpen),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accents.first,
                              side: BorderSide(
                                color: accents.first.withValues(alpha: 0.45),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      Align(
                        alignment: rtlUnitLine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSoon
                                ? LinearGradient(
                                    colors: [
                                      accents.first.withValues(alpha: 0.96),
                                      accents.last.withValues(alpha: 0.88),
                                    ],
                                  )
                                : null,
                            color: isSoon
                                ? null
                                : scheme.surface.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(12),
                            border: isSoon
                                ? Border.all(
                                    color: Colors.white.withValues(alpha: 0.34),
                                  )
                                : null,
                            boxShadow: isSoon
                                ? [
                                    BoxShadow(
                                      color: accents.first.withValues(
                                        alpha: 0.22,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Directionality(
                            textDirection: isSoon
                                ? TextDirection.ltr
                                : rtlUnitLine
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSoon
                                      ? Icons.hourglass_empty_rounded
                                      : Icons.layers_rounded,
                                  size: 16,
                                  color: isSoon ? Colors.white : accents.first,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  unitsValue.when(
                                    loading: () => l10n.loadingEllipsis,
                                    error: (_, __) => l10n.tapToOpen,
                                    data: (units) {
                                      if (units.isEmpty) return 'Soon...';
                                      final n = units.length;
                                      return '$n ${n == 1 ? l10n.unitSingular : l10n.unitPlural}';
                                    },
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: isSoon
                                            ? Colors.white
                                            : scheme.onSurfaceVariant,
                                        fontWeight: isSoon
                                            ? FontWeight.w900
                                            : FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

List<Color> homeBookCardAccents(int index) {
  const colors = [
    Colors.blue,
    Colors.purple,
    Colors.green,
    Colors.orange,
    Colors.red,
  ];
  return [colors[index % colors.length], colors[(index + 1) % colors.length]];
}
