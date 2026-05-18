import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/student/student_code_input.dart';
import '../../l10n/app_localizations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.wrapWithScaffold = true});

  /// See [LoginScreen.wrapWithScaffold] — avoid nested [Scaffold] inside [AuthHubScreen].
  final bool wrapWithScaffold;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _studentCodeCtrl = TextEditingController();
  var _obscure1 = true;
  var _obscure2 = true;
  var _registerAsStudent = false;
  var _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _studentCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final name = _nameCtrl.text.trim();
      await ref.read(authProvider.notifier).register(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
            displayName: name.isEmpty ? null : name,
            registerAsStudent: _registerAsStudent,
            studentCode: _registerAsStudent ? _studentCodeCtrl.text : null,
          );
      if (!mounted) {
        return;
      }
      context.go('/home');
    } catch (e) {
      if (!mounted) {
        return;
      }
      final raw = e.toString();
      final msg = raw.contains('Email already registered')
          ? l10n.registerEmailTaken
          : (raw.contains('Student code') ||
                  raw.contains('Invalid code') ||
                  raw.contains('already used') ||
                  raw.contains('expired'))
              ? l10n.invalidStudentCode
              : l10n.registerFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final body = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.newAccount,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.registerSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.displayNameOptional,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
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
              obscureText: _obscure1,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: l10n.password,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure1
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 8) {
                  return l10n.passwordMinLength;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscure2,
              decoration: InputDecoration(
                labelText: l10n.confirmPassword,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure2
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return l10n.confirmYourPassword;
                }
                if (v != _passwordCtrl.text) {
                  return l10n.passwordsNoMatch;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _registerAsStudent,
              onChanged: _submitting
                  ? null
                  : (v) => setState(() {
                        _registerAsStudent = v ?? false;
                        if (!_registerAsStudent) {
                          _studentCodeCtrl.clear();
                        }
                      }),
              title: Text(l10n.registerAsStudent),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_registerAsStudent) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _studentCodeCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: studentCodeInputFormatters,
                decoration: InputDecoration(
                  labelText: l10n.studentCodeLabel,
                  hintText: l10n.studentCodeFiveDigitsHint,
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) {
                  if (!_registerAsStudent) return null;
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) {
                    return l10n.studentCodeRequired;
                  }
                  if (!isValidStudentCode(s)) {
                    return l10n.studentCodeFiveDigitsInvalid;
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
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
                  : Text(l10n.register),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _submitting
                  ? null
                  : () => context.pushReplacement('/login'),
              child: Text(l10n.alreadyHaveAccount),
            ),
          ],
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
        title: Text(l10n.registerTitle),
      ),
      body: body,
    );
  }
}
