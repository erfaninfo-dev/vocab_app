import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/profile/profile_avatar.dart';
import '../../core/profile/profile_presets.dart';
import '../../data/models/auth_user.dart';
import '../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  String _selectedAvatarId = kDefaultAvatarId;
  var _saving = false;
  var _uploadingPhoto = false;
  var _loadedUserFields = false;
  String _initialName = '';
  String _initialAvatarId = kDefaultAvatarId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  void _syncFromUser(AuthUser user) {
    if (_loadedUserFields) {
      return;
    }
    _loadedUserFields = true;
    _initialName = user.displayName?.trim() ?? '';
    _initialAvatarId = user.avatar;
    _nameCtrl.text = _initialName;
    _selectedAvatarId = _initialAvatarId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    if (!_loadedUserFields) return false;
    return _nameCtrl.text.trim() != _initialName.trim() ||
        _selectedAvatarId != _initialAvatarId;
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) return true;
    final l10n = AppLocalizations.of(context)!;

    final res = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.unsavedChangesTitle),
        content: Text(l10n.unsavedChangesBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.discardStay),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.discardLeave),
          ),
        ],
      ),
    );

    return res ?? false;
  }

  /// [ImageCropper] is only reliable on Android/iOS (needs file path + native UI).
  bool get _useNativeCropper {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<Uint8List> _jpegBytesForUpload(Uint8List raw) async {
    try {
      final out = await FlutterImageCompress.compressWithList(
        raw,
        minWidth: 512,
        minHeight: 512,
        quality: 85,
        format: CompressFormat.jpeg,
      );
      if (out.isNotEmpty) return out;
    } catch (e) {
      debugPrint('FlutterImageCompress: $e');
    }
    if (raw.length > 10 * 1024 * 1024) {
      throw Exception('Image too large');
    }
    return raw;
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    XFile? x;
    try {
      final picker = ImagePicker();
      x = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
    } on PlatformException catch (e, st) {
      debugPrint('ImagePicker: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileUploadFailed)),
      );
      return;
    }
    if (x == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      late final Uint8List raw;

      if (_useNativeCropper) {
        try {
          final cropped = await ImageCropper().cropImage(
            sourcePath: x.path,
            compressFormat: ImageCompressFormat.jpg,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: l10n.profileCropPhoto,
                toolbarColor: Theme.of(context).colorScheme.surface,
                toolbarWidgetColor: Theme.of(context).colorScheme.onSurface,
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: true,
              ),
              IOSUiSettings(
                title: l10n.profileCropPhoto,
                aspectRatioLockEnabled: true,
              ),
            ],
          );
          if (cropped == null || !mounted) {
            return;
          }
          raw = await cropped.readAsBytes();
        } catch (e, st) {
          debugPrint('ImageCropper: $e\n$st');
          raw = await x.readAsBytes();
          if (raw.isEmpty) {
            throw Exception('Empty image');
          }
        }
      } else {
        raw = await x.readAsBytes();
        if (raw.isEmpty) {
          throw Exception('Empty image');
        }
      }

      final compressed = await _jpegBytesForUpload(raw);
      await ref.read(authProvider.notifier).uploadProfilePhoto(compressed);
      if (!mounted) return;
      final u = ref.read(authProvider).valueOrNull?.user;
      if (u != null) {
        setState(() => _selectedAvatarId = u.avatar);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profilePhotoUpdated)),
      );
    } catch (e, st) {
      debugPrint('Profile photo upload: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profileUploadFailed),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
            displayName: _nameCtrl.text.trim(),
            avatar: _selectedAvatarId,
          );
      if (!mounted) {
        return;
      }
      _initialName = _nameCtrl.text.trim();
      _initialAvatarId = _selectedAvatarId;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileSaved)),
      );
      context.pop();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileSaveFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final session = ref.watch(authProvider).valueOrNull;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profileScreenTitle)),
        body: Center(child: Text(l10n.profileSignInPrompt)),
      );
    }

    _syncFromUser(session.user);

    final boys = kProfilePresets.where((p) => p.id.startsWith('m')).toList();
    final girls = kProfilePresets.where((p) => p.id.startsWith('f')).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () async {
            if (_saving || _uploadingPhoto) return;
            final nav = Navigator.of(context);
            final ok = await _confirmDiscardChanges();
            if (!ok || !mounted) return;
            nav.pop();
          },
        ),
        title: Text(l10n.profileScreenTitle),
      ),
      body: PopScope(
        canPop: !_saving && !_uploadingPhoto,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (_saving || _uploadingPhoto) return;
          final nav = Navigator.of(context);
          final ok = await _confirmDiscardChanges();
          if (!ok || !mounted) return;
          nav.pop();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ProfileAvatar(
                    avatarId: _selectedAvatarId,
                    userId: session.user.id,
                    size: 96,
                    showBorder: true,
                  ),
                  if (_uploadingPhoto)
                    const SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _uploadingPhoto || _saving
                      ? null
                      : () => _pickAndUpload(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                  label: Text(l10n.profileGallery),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _uploadingPhoto || _saving
                      ? null
                      : () => _pickAndUpload(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined, size: 20),
                  label: Text(l10n.profileCamera),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              session.user.email,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.profileDisplayName,
                hintText: l10n.profileDisplayNameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.profilePresetAvatars,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.profileBoyAvatars,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            _AvatarGrid(
              presets: boys,
              selectedId: _selectedAvatarId,
              onSelect: (id) => setState(() => _selectedAvatarId = id),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.profileGirlAvatars,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            _AvatarGrid(
              presets: girls,
              selectedId: _selectedAvatarId,
              onSelect: (id) => setState(() => _selectedAvatarId = id),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: (_saving || _uploadingPhoto) ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: (_saving || _uploadingPhoto)
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarGrid extends StatelessWidget {
  const _AvatarGrid({
    required this.presets,
    required this.selectedId,
    required this.onSelect,
  });

  final List<ProfilePreset> presets;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: presets.map((p) {
        final sel = p.id == selectedId;
        return InkWell(
          onTap: () => onSelect(p.id),
          customBorder: const CircleBorder(),
          child: Tooltip(
            message: p.label,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: sel ? 3 : 1,
                  color: sel
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: p.background,
                child: Icon(
                  p.icon,
                  color: p.foreground,
                  size: 28,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
