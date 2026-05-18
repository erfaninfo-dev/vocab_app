import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../home_release_notes_provider.dart';

class HomeReleaseNotesBanner extends ConsumerWidget {
  const HomeReleaseNotesBanner({super.key});

  Future<void> _dismiss(WidgetRef ref, int versionCode) =>
      dismissHomeReleaseNotes(ref, versionCode);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotes = ref.watch(homeReleaseNotesProvider);
    final notes = asyncNotes.valueOrNull;
    if (notes == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final bullets = _releaseNoteBulletLines(notes.body);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primary.withValues(alpha: 0.92),
                        scheme.tertiary.withValues(alpha: 0.88),
                        scheme.secondary.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: rtl ? null : -28,
                left: rtl ? -28 : null,
                top: -20,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Icon(
                            Icons.rocket_launch_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              l10n.homeNewUpdatesTitle,
                              textAlign:
                                  rtl ? TextAlign.right : TextAlign.left,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: l10n.close,
                          onPressed: () => _dismiss(ref, notes.versionCode),
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < bullets.length; i++)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: i < bullets.length - 1 ? 8 : 0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  textDirection: rtl
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        size: 18,
                                        color: Colors.white
                                            .withValues(alpha: 0.95),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        bullets[i],
                                        textAlign: rtl
                                            ? TextAlign.right
                                            : TextAlign.left,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.white
                                                  .withValues(alpha: 0.96),
                                              height: 1.45,
                                              fontWeight: FontWeight.w500,
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
                    const SizedBox(height: 14),
                    Align(
                      alignment:
                          rtl ? Alignment.centerLeft : Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () => _dismiss(ref, notes.versionCode),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: scheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Icon(
                          rtl
                              ? Icons.arrow_back_rounded
                              : Icons.arrow_forward_rounded,
                          size: 20,
                        ),
                        label: Text(
                          l10n.homeNewUpdatesLetsGo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
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

List<String> _releaseNoteBulletLines(String body) {
  final normalized = body.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final raw = normalized.split('\n');
  final lines = <String>[];
  for (final part in raw) {
    var line = part.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('•')) {
      line = line.substring(1).trimLeft();
    } else if (line.startsWith('-') || line.startsWith('*')) {
      line = line.substring(1).trimLeft();
    }
    if (line.isNotEmpty) lines.add(line);
  }
  if (lines.isEmpty && body.trim().isNotEmpty) {
    lines.add(body.trim());
  }
  return lines;
}
