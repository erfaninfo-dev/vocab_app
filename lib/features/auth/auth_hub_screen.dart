import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthHubScreen extends StatefulWidget {
  const AuthHubScreen({super.key});

  @override
  State<AuthHubScreen> createState() => _AuthHubScreenState();
}

class _AuthHubScreenState extends State<AuthHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: Text(l10n.accountTitle),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text(l10n.skip),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: l10n.tabSignIn),
            Tab(text: l10n.tabRegister),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          LoginScreen(wrapWithScaffold: false),
          RegisterScreen(wrapWithScaffold: false),
        ],
      ),
    );
  }
}
