import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/profile/profile_avatar.dart';
import '../../data/models/admin_story.dart';
import 'story_providers.dart';

class AdminStoryAudienceScreen extends ConsumerWidget {
  const AdminStoryAudienceScreen({super.key, required this.storyId});

  final int storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(storyAudienceProvider(storyId));
    return Scaffold(
      appBar: AppBar(title: const Text('Story audience')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load audience: $e')),
        data: (summary) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.visibility_rounded,
                    label: 'Views',
                    value: summary.viewCount,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.favorite_rounded,
                    label: 'Likes',
                    value: summary.likeCount,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _PeopleSection(
              title: 'Viewed by',
              empty: 'No views yet',
              people: summary.viewers,
            ),
            const SizedBox(height: 20),
            _PeopleSection(
              title: 'Liked by',
              empty: 'No likes yet',
              people: summary.likers,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _PeopleSection extends StatelessWidget {
  const _PeopleSection({
    required this.title,
    required this.empty,
    required this.people,
  });

  final String title;
  final String empty;
  final List<StoryAudienceUser> people;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (people.isEmpty)
              Padding(padding: const EdgeInsets.all(16), child: Text(empty))
            else
              for (final p in people)
                ListTile(
                  leading: ProfileAvatar(
                    avatarId: p.avatar,
                    userId: p.id,
                    size: 42,
                  ),
                  title: Text(p.displayLabel),
                  subtitle: Text(p.email),
                  trailing: Text(_formatWhen(p.happenedAt)),
                ),
          ],
        ),
      ),
    );
  }
}

String _formatWhen(String raw) {
  final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
  final dt = DateTime.tryParse(normalized)?.toLocal();
  if (dt == null) return raw;
  final m = dt.minute.toString().padLeft(2, '0');
  return '${dt.month}/${dt.day} ${dt.hour}:$m';
}
