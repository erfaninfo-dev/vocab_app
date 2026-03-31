import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_mode_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final controller = ref.read(themeModeProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primary.withOpacity(0.06), scheme.surface],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            Card(
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: mode,
                    onChanged: (value) {
                      if (value != null) {
                        controller.setThemeMode(value);
                      }
                    },
                    title: const Text('System theme'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: mode,
                    onChanged: (value) {
                      if (value != null) {
                        controller.setThemeMode(value);
                      }
                    },
                    title: const Text('Light mode'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: mode,
                    onChanged: (value) {
                      if (value != null) {
                        controller.setThemeMode(value);
                      }
                    },
                    title: const Text('Dark mode'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('About'),
                subtitle: Text(
                  'IELTS Essential Words\nFlutter + Riverpod + go_router',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
