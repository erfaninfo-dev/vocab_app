import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/profile/profile_avatar.dart';
import '../../core/profile/profile_presets.dart';
import '../../data/models/auth_user.dart';

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
    _nameCtrl.text = user.displayName?.trim() ?? '';
    _selectedAvatarId = user.avatar;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
    );
    if (x == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final raw = await x.readAsBytes();
      final compressed = await FlutterImageCompress.compressWithList(
        raw,
        minWidth: 512,
        minHeight: 512,
        quality: 85,
        format: CompressFormat.jpeg,
      );
      await ref.read(authProvider.notifier).uploadProfilePhoto(compressed);
      if (!mounted) return;
      final u = ref.read(authProvider).valueOrNull?.user;
      if (u != null) {
        setState(() => _selectedAvatarId = u.avatar);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo updated')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload failed. Try again or pick a smaller image.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
            displayName: _nameCtrl.text.trim(),
            avatar: _selectedAvatarId,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ذخیره انجام نشد. لطفاً دوباره تلاش کنید')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = ref.watch(authProvider).valueOrNull;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Sign in to edit your profile.')),
      );
    }

    _syncFromUser(session.user);

    final boys = kProfilePresets.where((p) => p.id.startsWith('m')).toList();
    final girls = kProfilePresets.where((p) => p.id.startsWith('f')).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
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
                  label: const Text('Gallery'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _uploadingPhoto || _saving
                      ? null
                      : () => _pickAndUpload(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined, size: 20),
                  label: const Text('Camera'),
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
              decoration: const InputDecoration(
                labelText: 'Display name',
                hintText: 'How your name appears',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Or pick a preset avatar',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 20),
            Text(
              'Boy avatars',
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
              'Girl avatars',
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
                  : const Text('Save'),
            ),
          ],
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
