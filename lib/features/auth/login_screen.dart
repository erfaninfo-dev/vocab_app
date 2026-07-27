import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_jelly_style.dart';
import '../../core/auth/auth_provider.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

/// لینک یا آیدی پشتیبانی برای بازنشانی رمز (روبیکا و غیره) — در صورت نیاز عوض کنید.
const String kPasswordResetSupportLaunchUri = 'https://rubika.ir';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.wrapWithScaffold = true});

  /// When embedded in [AuthHubScreen] [TabBarView], omit [Scaffold] to avoid
  /// nested scaffolds (fixes dim/grey overlay under RTL e.g. Kurdish).
  final bool wrapWithScaffold;

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
    final l10n = AppLocalizations.of(context)!;
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
          ? l10n.loginInvalid
          : l10n.loginFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _showForgotPasswordSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final emailHint = _emailCtrl.text.trim();
    final emailCtrl = TextEditingController(text: emailHint);
    final codeCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final pass2Ctrl = TextEditingController();
    var sending = false;
    var confirming = false;
    var sent = false;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 8,
              bottom: 24 + MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: StatefulBuilder(
              builder: (ctx, setModalState) {
                Future<void> sendCode() async {
                  final email = emailCtrl.text.trim();
                  if (email.isEmpty || !email.contains('@')) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(l10n.enterValidEmail)),
                    );
                    return;
                  }
                  setModalState(() => sending = true);
                  try {
                    await ref
                        .read(apiServiceProvider)
                        .requestPasswordResetEmailCode(email);
                    sent = true;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(l10n.passwordResetCodeSent)),
                    );
                  } catch (_) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(l10n.passwordResetSendFailed)),
                    );
                  } finally {
                    setModalState(() => sending = false);
                  }
                }

                Future<void> confirm() async {
                  final email = emailCtrl.text.trim();
                  final code = codeCtrl.text.trim();
                  final p1 = passCtrl.text;
                  final p2 = pass2Ctrl.text;
                  if (code.length != 6) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(l10n.passwordResetInvalidCode)),
                    );
                    return;
                  }
                  if (p1.length < 8) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(l10n.passwordMinLength)),
                    );
                    return;
                  }
                  if (p1 != p2) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(l10n.passwordResetPasswordsMismatch)),
                    );
                    return;
                  }
                  setModalState(() => confirming = true);
                  try {
                    await ref.read(apiServiceProvider).confirmPasswordResetEmailCode(
                          email: email,
                          code: code,
                          newPassword: p1,
                        );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.passwordResetSuccess)),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().contains('Invalid code')
                              ? l10n.passwordResetInvalidCode
                              : l10n.passwordResetChangeFailed,
                        ),
                      ),
                    );
                  } finally {
                    setModalState(() => confirming = false);
                  }
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.passwordResetTitle,
                      style: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: sending ? null : sendCode,
                      icon: sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.mark_email_unread_rounded),
                      label: Text(l10n.passwordResetSendCode),
                    ),
                    const SizedBox(height: 12),
                    if (sent) ...[
                      TextField(
                        controller: codeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.passwordResetCodeLabel,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n.passwordResetNewPassword,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pass2Ctrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n.passwordResetConfirmPassword,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: confirming ? null : confirm,
                        child: confirming
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.passwordResetChangeButton),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.passwordResetHelper,
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: kPasswordResetSupportLaunchUri),
                        );
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(l10n.supportLinkCopied)),
                        );
                      },
                      child: Text(l10n.copySupportLink),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.close),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    emailCtrl.dispose();
    codeCtrl.dispose();
    passCtrl.dispose();
    pass2Ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final body = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: AppJellyCard(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              l10n.welcomeBack,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.loginSubtitle,
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
              decoration: InputDecoration(
                labelText: l10n.email,
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) {
                  return l10n.enterEmail;
                }
                if (!s.contains('@')) {
                  return l10n.enterValidEmail;
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
                labelText: l10n.password,
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
                  return l10n.enterPassword;
                }
                if (v.length < 8) {
                  return l10n.passwordMinLength;
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
                child: Text(l10n.forgotPassword),
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
                  : Text(l10n.signInButton),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _submitting ? null : () => context.push('/register'),
              child: Text(l10n.createAnAccount),
            ),
          ],
        ),
      ),
      ),
    );

    if (!widget.wrapWithScaffold) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.loginTitle),
      ),
      body: body,
    );
  }
}
