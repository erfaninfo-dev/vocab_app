import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Account'),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Skip'),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Sign in'),
            Tab(text: 'Register'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          LoginScreen(),
          RegisterScreen(),
        ],
      ),
    );
  }
}

