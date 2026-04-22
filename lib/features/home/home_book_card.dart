import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/book_model.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

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
    final accents = homeBookCardAccents(index);
    final locale = Localizations.localeOf(context);
    final rtlUnitLine =
        locale.languageCode == 'fa' || locale.languageCode == 'ckb';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accents.first.withValues(alpha: 0.18),
                accents.last.withValues(alpha: 0.08),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accents.first.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      color: accents.first,
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

              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),

              const SizedBox(height: 3),

              Align(
                alignment: rtlUnitLine
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Directionality(
                  textDirection: rtlUnitLine
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: Text(
                    unitsValue.when(
                      loading: () => l10n.loadingEllipsis,
                      error: (_, __) => l10n.tapToOpen,
                      data: (units) {
                        final n = units.length;
                        return '$n ${n == 1 ? l10n.unitSingular : l10n.unitPlural}';
                      },
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              if ((book.description ?? '').isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: accents.first,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          book.description!,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
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
