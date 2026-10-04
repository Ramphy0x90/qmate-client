import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api_client.dart';
import '../../../core/routes.dart';
import '../../../core/session.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api, required this.session});

  final ApiClient api;
  final Session session;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final (token, user) = await widget.api.login(_username.text, _password.text);
      // The router's redirect takes it from here.
      await widget.session.signIn(token, user);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.statusCode == 401 ? 'Wrong username or password.' : e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Find someone to game, walk or study with.',
      error: _error,
      busy: _busy,
      submitLabel: 'Log in',
      onSubmit: _submit,
      footer: TextButton(
        onPressed: _busy ? null : () => context.go(Routes.register),
        child: const Text('New here? Create an account'),
      ),
      fields: [
        TextField(
          controller: _username,
          decoration: const InputDecoration(labelText: 'Username'),
          autocorrect: false,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
        ),
        TextField(
          controller: _password,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}
