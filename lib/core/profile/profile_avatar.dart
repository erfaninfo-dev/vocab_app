import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/api_service.dart';
import 'profile_photo_cache.dart';
import 'profile_presets.dart';

/// Circular avatar: preset icons, or a network photo when [avatarId] is
/// `custom` / an uploaded avatar path.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    super.key,
    required this.avatarId,
    this.userId,
    this.size = 44,
    this.showBorder = false,
  });

  final String avatarId;

  /// Required for loading `custom` photo from the API.
  final int? userId;
  final double size;
  final bool showBorder;

  static bool isCustomPhoto(String id) => id.trim().toLowerCase() == 'custom';

  static bool isPhotoPath(String id) {
    final value = id.trim().toLowerCase();
    return value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('uploads/avatars/');
  }

  static String customPhotoUrl(int userId, int cacheNonce) {
    final base = kApiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base/uploads/avatars/$userId.jpg?v=$cacheNonce';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final id = avatarId.trim();
    final uid = userId;

    if ((isCustomPhoto(id) && uid != null && uid > 0) || isPhotoPath(id)) {
      final nonce = ref.watch(profilePhotoCacheNonceProvider);
      final url = isPhotoPath(id)
          ? apiAbsoluteMediaUrl(id)
          : customPhotoUrl(uid!, nonce);
      return Container(
        width: size,
        height: size,
        decoration: showBorder
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scheme.primary, width: 2),
              )
            : null,
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _FallbackPreset(size: size, scheme: scheme, showBorder: false),
              Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      );
    }

    final p = profilePresetForId(id);
    return Container(
      width: size,
      height: size,
      decoration: showBorder
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scheme.primary, width: 2),
            )
          : null,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: p.background,
        child: Icon(p.icon, color: p.foreground, size: size * 0.52),
      ),
    );
  }
}

class _FallbackPreset extends StatelessWidget {
  const _FallbackPreset({
    required this.size,
    required this.scheme,
    required this.showBorder,
  });

  final double size;
  final ColorScheme scheme;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final p = profilePresetForId(kDefaultAvatarId);
    return Container(
      width: size,
      height: size,
      decoration: showBorder
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scheme.primary, width: 2),
            )
          : null,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: p.background,
        child: Icon(p.icon, color: p.foreground, size: size * 0.52),
      ),
    );
  }
}
