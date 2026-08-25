import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_info/package_info_provider.dart';
import '../../core/locale/ui_locale_provider.dart';
import '../../domain/api_providers.dart';

const kReleaseNotesSeenBuildKey = 'release_notes_seen_build_v1';

class HomeReleaseNotesContent {
  const HomeReleaseNotesContent({
    required this.versionCode,
    required this.body,
  });

  final int versionCode;
  final String body;
}

final homeReleaseNotesProvider =
    FutureProvider<HomeReleaseNotesContent?>((ref) async {
  final pkg = await ref.watch(packageInfoProvider.future);
  final build = int.tryParse(pkg.buildNumber) ?? 0;
  if (build <= 0) return null;

  final prefs = await SharedPreferences.getInstance();
  if ((prefs.getInt(kReleaseNotesSeenBuildKey) ?? 0) >= build) {
    return null;
  }

  final api = ref.watch(apiServiceProvider);
  final isWindows =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  final manifest = await api.fetchAppUpdateManifest(
    installedVersion: build,
    installedVersionName: pkg.version,
    platform: isWindows ? 'windows' : 'android',
  );
  if (manifest == null) return null;

  final locale = ref.watch(uiLocaleProvider);
  final body = manifest.releaseNotes.bodyFor(locale).trim();
  if (body.isEmpty) return null;

  return HomeReleaseNotesContent(versionCode: build, body: body);
});

Future<void> dismissHomeReleaseNotes(WidgetRef ref, int versionCode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(kReleaseNotesSeenBuildKey, versionCode);
  ref.invalidate(homeReleaseNotesProvider);
}
