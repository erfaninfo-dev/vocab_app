import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';

/// لینک یا آیدی پشتیبانی برای بازنشانی رمز (روبیکا و غیره) — در صورت نیاز عوض کنید.
const String kPasswordResetSupportLaunchUri = 'https://rubika.ir';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  var _obscure = true;
  var _submitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(authProvider.notifier)
          .login(_emailCtrl.text, _passwordCtrl.text);
      if (!mounted) {
        return;
      }
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      final msg = e.toString().contains('Invalid email or password')
          ? 'ایمیل یا رمز عبور اشتباه است'
          : 'ورود انجام نشد. لطفاً دوباره تلاش کنید';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _showForgotPasswordSheet(BuildContext context) async {
    final emailHint = _emailCtrl.text.trim();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 8,
                bottom: 24 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'بازنشانی رمز عبور',
                    textAlign: TextAlign.right,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'به‌دلیل قطع یا محدودیت اینترنت بین‌الملل، ارسال ایمیل برای بازنشانی '
                    'رمز در حال حاضر ممکن نیست. برای درخواست بازنشانی رمز عبور، در '
                    'بله یا روبیکا به آیدی erfaninfox پیام دهید.',
                    textAlign: TextAlign.right,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: kPasswordResetSupportLaunchUri),
                      );
                      if (!ctx.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'لینک پشتیبانی کپی شد — در مرورگر یا روبیکا باز کنید',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('کپی لینک پشتیبانی'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final buf = StringBuffer()
                        ..writeln('سلام،')
                        ..writeln(
                          'درخواست بازنشانی رمز عبور برای اپ «IELTS Essential Words» دارم.',
                        );
                      if (emailHint.isNotEmpty) {
                        buf.writeln('ایمیل ثبت‌نام: $emailHint');
                      }
                      buf.writeln('آیدی پشتیبانی در بله/روبیکا: erfaninfox');
                      await Clipboard.setData(ClipboardData(text: buf.toString()));
                      if (!ctx.mounted) {
                        return;
                      }
                      Navigator.pop(ctx);
                      if (!mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'متن درخواست کپی شد — آن را در بله یا روبیکا بفرستید',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('کپی متن درخواست'),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('بستن'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Sign in'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use your email and password. No verification step — your account is active immediately.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) {
                    return 'Enter your email';
                  }
                  if (!s.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Enter your password';
                  }
                  if (v.length < 8) {
                    return 'At least 8 characters';
                  }
                  return null;
                },
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _submitting
                      ? null
                      : () => _showForgotPasswordSheet(context),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _submitting ? null : () => context.push('/register'),
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
