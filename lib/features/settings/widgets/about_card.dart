import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_info/package_info_provider.dart';
import '../../../core/branding/app_brand_logo.dart';
import '../../../core/network/resolve_update_url.dart';
import '../../../core/update/apk_download_dialog.dart';
import '../../../domain/app_update_provider.dart';
import '../../../l10n/app_localizations.dart';

const String kAboutSupportPhoneDisplay = '09107837602';
const String kAboutSupportPhoneUri = 'tel:+989107837602';

final aboutUpdateDismissedProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

Future<void> openAboutLatestDownloadLink(BuildContext context, String url) async {
  final l10n = AppLocalizations.of(context)!;
  final uri = resolveUpdateDownloadUrl(url);
  if (uri == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aboutCouldNotOpenLink)),
      );
    }
    return;
  }
  try {
    var launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aboutCouldNotOpenLink)),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aboutCouldNotOpenLink)),
      );
    }
  }
}

Future<void> openAboutSupportPhone(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final uri = Uri.parse(kAboutSupportPhoneUri);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aboutCouldNotOpenLink)),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aboutCouldNotOpenLink)),
      );
    }
  }
}

class AboutCard extends ConsumerWidget {
  const AboutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final l10nEn = lookupAppLocalizations(const Locale('en'));

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AboutHeroHeader(
            appName: l10nEn.appNameShort,
            authorLabel: l10nEn.byAuthor,
            primary: scheme.primary,
            tertiary: scheme.tertiary,
          ),
          ColoredBox(
            color: scheme.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
              child: Column(
                children: [
                  const AboutUpdateSection(),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _AboutActionChip(
                          icon: Icons.public_rounded,
                          label: 'Website',
                          value: 'erfaninfo.com',
                          gradient: const [
                            Color(0xFF4F5FD8),
                            Color(0xFF6B7AFF),
                          ],
                          onTap: () {
                            Clipboard.setData(
                              const ClipboardData(text: 'www.erfaninfo.com'),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.linkCopied),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AboutActionChip(
                          icon: Icons.phone_rounded,
                          label: l10n.aboutPhoneLabel,
                          value: kAboutSupportPhoneDisplay,
                          valueLtr: true,
                          gradient: const [
                            Color(0xFF5B4FCF),
                            Color(0xFF8B6CE8),
                          ],
                          onTap: () => openAboutSupportPhone(context),
                          onLongPress: () {
                            Clipboard.setData(
                              const ClipboardData(
                                text: kAboutSupportPhoneDisplay,
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.aboutPhoneCopied),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
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
    );
  }
}

class _AboutHeroHeader extends StatelessWidget {
  const _AboutHeroHeader({
    required this.appName,
    required this.authorLabel,
    required this.primary,
    required this.tertiary,
  });

  final String appName;
  final String authorLabel;
  final Color primary;
  final Color tertiary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 272,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(primary, const Color(0xFF2A3A9E), 0.35)!,
                    primary,
                    Color.lerp(tertiary, const Color(0xFF9B6BFF), 0.25)!,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _AboutHeroPatternPainter(
                ringColor: Colors.white.withValues(alpha: 0.12),
                dotColor: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            top: 18,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 28,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Positioned(
            top: 22,
            left: 0,
            right: 0,
            child: const Center(child: AboutSharpLogo(size: 112)),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 36,
            child: Column(
              children: [
                Text(
                  appName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        authorLabel,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 28),
              painter: _AboutWavePainter(
                fill: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// High-resolution logo — never use tiny [app_icon.png] upscaled here.
class AboutSharpLogo extends StatelessWidget {
  const AboutSharpLogo({super.key, this.size = 112});

  final double size;

  static const _logoPath = 'assets/branding/logo.png';

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cachePx = (size * dpr).round().clamp(64, 512);

    return Container(
      width: size + 18,
      height: size + 18,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E2A6E).withValues(alpha: 0.4),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF3949AB).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(9),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          _logoPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          cacheWidth: cachePx,
          cacheHeight: cachePx,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return AppBrandLogoFallback(size: size, borderRadius: 20);
          },
        ),
      ),
    );
  }
}

class _AboutHeroPatternPainter extends CustomPainter {
  _AboutHeroPatternPainter({
    required this.ringColor,
    required this.dotColor,
  });

  final Color ringColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final dot = Paint()..color = dotColor;

    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.22), 52, ring);
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.62), 36, ring);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.78), 24, ring);

    for (var i = 0; i < 8; i++) {
      final x = size.width * (0.08 + i * 0.11);
      canvas.drawCircle(Offset(x, size.height * 0.12), 2.2, dot);
    }
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.92, size.height * (0.45 + i * 0.08)),
        2.5,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AboutHeroPatternPainter oldDelegate) => false;
}

class _AboutWavePainter extends CustomPainter {
  _AboutWavePainter({required this.fill});

  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.05,
        size.width * 0.5,
        size.height * 0.35,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.62,
        size.width,
        size.height * 0.2,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(covariant _AboutWavePainter oldDelegate) =>
      oldDelegate.fill != fill;
}

class _AboutActionChip extends StatelessWidget {
  const _AboutActionChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    required this.onTap,
    this.onLongPress,
    this.valueLtr = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool valueLtr;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (valueLtr)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AboutUpdateSection extends ConsumerWidget {
  const AboutUpdateSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final packageAsync = ref.watch(packageInfoProvider);
    final updateAsync = ref.watch(appUpdateCheckProvider);
    final dismissed = ref.watch(aboutUpdateDismissedProvider);

    Widget panel({required List<Widget> children}) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(children: children),
      );
    }

    return packageAsync.when(
      data: (info) {
        final versionLabel =
            l10n.aboutAppVersion(info.version, info.buildNumber);
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.12),
                    scheme.tertiary.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    versionLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            updateAsync.when(
              data: (check) {
                if (check.checkFailed) {
                  return panel(
                    children: [
                      Text(
                        l10n.aboutUpdateCheckFailed,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () =>
                            ref.invalidate(appUpdateCheckProvider),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.aboutRetryUpdateCheck),
                      ),
                    ],
                  );
                }

                if (check.androidEligible) {
                  if (check.updateAvailable &&
                      check.apkUrl != null &&
                      check.apkUrl!.isNotEmpty) {
                    final verLabel =
                        (check.remoteVersionName ?? '').trim().isNotEmpty
                            ? check.remoteVersionName!.trim()
                            : '${check.remoteVersionCode ?? ''}';
                    return panel(
                      children: [
                        Text(
                          l10n.aboutUpdateAvailableVersion(verLabel),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!dismissed || check.forceUpdate)
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: () => showApkDownloadProgressDialog(
                                  context,
                                  check.apkUrl!,
                                ),
                                icon: const Icon(Icons.download_rounded),
                                label: Text(l10n.aboutDownloadApkUpdate),
                              ),
                              if (!check.forceUpdate)
                                TextButton(
                                  onPressed: () => ref
                                      .read(
                                        aboutUpdateDismissedProvider.notifier,
                                      )
                                      .state = true,
                                  child: Text(l10n.aboutLater),
                                ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Text(
                          check.forceUpdate
                              ? l10n.aboutForcedUpdateNote
                              : l10n.aboutInstallApkHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  }
                  return panel(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: scheme.primary,
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.aboutAppUpToDate,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }

                if (check.apkUrl == null || check.apkUrl!.isEmpty) {
                  return const SizedBox.shrink();
                }
                if (check.updateAvailable) {
                  final verLabel =
                      (check.remoteVersionName ?? '').trim().isNotEmpty
                          ? check.remoteVersionName!.trim()
                          : '${check.remoteVersionCode ?? ''}';
                  return panel(
                    children: [
                      Text(
                        l10n.aboutUpdateAvailableVersion(verLabel),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (check.forceUpdate) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.aboutForcedUpdateNote,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => openAboutLatestDownloadLink(
                          context,
                          check.apkUrl!,
                        ),
                        icon: const Icon(Icons.system_update_rounded),
                        label: Text(l10n.aboutUpdateFromPlayStore),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox(
                height: 36,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, __) => panel(
                children: [
                  Text(
                    l10n.aboutUpdateCheckFailed,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => ref.invalidate(appUpdateCheckProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.aboutRetryUpdateCheck),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 28,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
