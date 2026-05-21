import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../home_release_notes_provider.dart';

/// Full-screen blocking overlay on Home when release notes are available.
class HomeReleaseNotesOverlayGate extends ConsumerWidget {
  const HomeReleaseNotesOverlayGate({
    super.key,
    required this.child,
    this.show = true,
  });

  final Widget child;
  final bool show;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(homeReleaseNotesProvider).valueOrNull;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (show && notes != null) _HomeReleaseNotesOverlay(notes: notes),
      ],
    );
  }
}

class _HomeReleaseNotesOverlay extends ConsumerStatefulWidget {
  const _HomeReleaseNotesOverlay({required this.notes});

  final HomeReleaseNotesContent notes;

  @override
  ConsumerState<_HomeReleaseNotesOverlay> createState() =>
      _HomeReleaseNotesOverlayState();
}

class _HomeReleaseNotesOverlayState extends ConsumerState<_HomeReleaseNotesOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() =>
      dismissHomeReleaseNotes(ref, widget.notes.versionCode);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: FadeTransition(
        opacity: _fade,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () {},
                behavior: HitTestBehavior.opaque,
                child: ColoredBox(
                  color: scheme.scrim.withValues(alpha: 0.62),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SlideTransition(
                    position: _slide,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _ReleaseNotesCard(
                          notes: widget.notes,
                          onDismiss: _dismiss,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReleaseNotesCard extends ConsumerWidget {
  const _ReleaseNotesCard({
    required this.notes,
    required this.onDismiss,
  });

  final HomeReleaseNotesContent notes;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final bullets = _releaseNoteBulletLines(notes.body);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primary.withValues(alpha: 0.94),
                        scheme.tertiary.withValues(alpha: 0.9),
                        scheme.secondary.withValues(alpha: 0.86),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: rtl ? null : -32,
                left: rtl ? -32 : null,
                top: -24,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 140,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.38),
                            ),
                          ),
                          child: const Icon(
                            Icons.rocket_launch_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              l10n.homeNewUpdatesTitle,
                              textAlign:
                                  rtl ? TextAlign.right : TextAlign.left,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.15,
                                  ),
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: l10n.close,
                          onPressed: onDismiss,
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < bullets.length; i++)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: i < bullets.length - 1 ? 10 : 0,
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
                                        size: 20,
                                        color: Colors.white
                                            .withValues(alpha: 0.96),
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
                                            .bodyLarge
                                            ?.copyWith(
                                              color: Colors.white
                                                  .withValues(alpha: 0.96),
                                              height: 1.5,
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
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onDismiss,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: scheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(
                          rtl
                              ? Icons.arrow_back_rounded
                              : Icons.arrow_forward_rounded,
                          size: 22,
                        ),
                        label: Text(
                          l10n.homeNewUpdatesLetsGo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
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
