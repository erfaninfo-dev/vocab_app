import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        SnackBar(content: Text('$e')),
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
              child: ProfileAvatar(
                avatarId: _selectedAvatarId,
                size: 96,
              ),
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
            const SizedBox(height: 28),
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
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _saving
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
