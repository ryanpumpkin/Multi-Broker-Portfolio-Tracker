import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/auth_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({
    super.key,
    this.onSignedIn,
    this.onCreateAccount,
    this.onForgotPassword,
  });

  final VoidCallback? onSignedIn;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onForgotPassword;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authProvider.notifier).signIn(
            email: _email.text.trim(),
            password: _password.text,
          );
      widget.onSignedIn?.call();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final loading = auth.isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              key: const Key('sign_in_email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              key: const Key('sign_in_password'),
              controller: _password,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: loading ? null : (_) => _submit(),
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('sign_in_submit'),
              onPressed: loading ? null : _submit,
              child: const Text('Sign in'),
            ),
            TextButton(
              key: const Key('sign_in_forgot_password'),
              onPressed: widget.onForgotPassword,
              child: const Text('Forgot password?'),
            ),
            TextButton(
              key: const Key('sign_in_create_account'),
              onPressed: widget.onCreateAccount,
              child: const Text('Create account'),
            ),
            if (auth.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  auth.error.toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
