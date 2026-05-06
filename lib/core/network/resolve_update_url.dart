import '../../data/services/api_service.dart';

Uri _joinedWithApiOriginAndPath(Uri base, String relativePath) {
  final trimmed = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
  final basePathRaw = base.path.isEmpty ? '' : base.path;
  final baseNorm =
      basePathRaw.endsWith('/') ? basePathRaw.substring(0, basePathRaw.length - 1) : basePathRaw;
  final path = '${baseNorm.isEmpty ? '/' : '$baseNorm/'}$trimmed'.replaceFirst(RegExp(r'^//'), '/');
  final normalized = path.startsWith('/') ? path : '/$path';
  return base.replace(path: normalized);
}

/// Normalizes URLs from [app_update.php] (`apk_url`) for launcher or downloader.
///
/// Handles relative paths against [kApiBaseUrl], URLs without scheme, and
/// protocol-relative URLs (`//example.com/...`).
Uri? resolveUpdateDownloadUrl(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;

  if (t.startsWith('//')) {
    return Uri.tryParse('https:$t');
  }

  final parsed = Uri.tryParse(t);
  if (parsed != null &&
      parsed.scheme.isNotEmpty &&
      {'http', 'https', 'market', 'intent'}.contains(parsed.scheme)) {
    return parsed;
  }

  if (!t.contains('://') && !t.startsWith('/') && !t.startsWith('//')) {
    final direct = Uri.tryParse('https://$t');
    if (direct != null && direct.hasAuthority && direct.host.contains('.')) {
      return direct;
    }
  }

  try {
    final base = Uri.parse(kApiBaseUrl);
    if (!base.hasScheme || base.host.isEmpty) return Uri.tryParse('https://$t');

    if (t.startsWith('/')) {
      return base.replace(path: t);
    }

    return _joinedWithApiOriginAndPath(base, t);
  } catch (_) {
    return Uri.tryParse('https://$t');
  }
}
