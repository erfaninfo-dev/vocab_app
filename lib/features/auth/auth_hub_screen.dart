import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/api_full_refresh.dart';
import '../../l10n/app_localizations.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthHubScreen extends ConsumerStatefulWidget {
  const AuthHubScreen({super.key});

  @override
  ConsumerState<AuthHubScreen> createState() => _AuthHubScreenState();
}

class _AuthHubScreenState extends ConsumerState<AuthHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  void _exitAuth(BuildContext context) {
    final state = GoRouterState.of(context);
    final from = state.uri.queryParameters['from']?.trim();
    if (from != null && from.isNotEmpty) {
      context.go(from);
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_prefetchBooksList());
    });
  }

  Future<void> _prefetchBooksList() async {
    if (!mounted) return;
    await prefetchBooksCatalogForHome(ref);
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
          onPressed: () => _exitAuth(context),
        ),
        title: Text(l10n.accountTitle),
        actions: [
          TextButton(
            onPressed: () => _exitAuth(context),
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
