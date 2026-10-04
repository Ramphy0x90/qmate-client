import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api_client.dart';
import '../../../core/legal.dart';
import '../../../core/models.dart';
import '../../../core/routes.dart';
import '../../../core/session.dart';
import '../../../shared/widgets/chip_multi_select.dart';
import '../../../shared/widgets/legal_links.dart';
import '../widgets/auth_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.api, required this.session});

  final ApiClient api;
  final Session session;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();
  final _bio = TextEditingController();
  Set<RoleTag> _roleTags = {};
  Set<ActivityType> _prefs = {};
  bool _adultConfirmed = false;
  bool _acceptTerms = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _password.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final (token, user) = await widget.api.register(
        username: _username.text,
        displayName: _displayName.text,
        password: _password.text,
        bio: _bio.text,
        roleTags: _roleTags.toList(),
        activityPrefs: _prefs.toList(),
        adultConfirmed: _adultConfirmed,
        acceptTerms: _acceptTerms,
      );
      await widget.session.signIn(token, user);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.titleSmall;
    return AuthScaffold(
      title: 'Create your profile',
      subtitle: 'Qmate is for friendly, platonic company. Be kind.',
      error: _error,
      busy: _busy,
      submitLabel: 'Create account',
      onSubmit: _adultConfirmed && _acceptTerms ? _submit : null,
      footer: TextButton(
        onPressed: _busy ? null : () => context.go(Routes.login),
        child: const Text('Already have an account? Log in'),
      ),
      fields: [
        TextField(
          controller: _username,
          decoration: const InputDecoration(labelText: 'Username', helperText: '3–20 characters: a–z, 0–9, _'),
          autocorrect: false,
          maxLength: 20,
          autofillHints: const [AutofillHints.newUsername],
        ),
        TextField(
          controller: _displayName,
          decoration: const InputDecoration(labelText: 'Display name'),
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
        ),
        TextField(
          controller: _password,
          decoration: const InputDecoration(labelText: 'Password', helperText: 'At least 8 characters'),
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
        ),
        TextField(
          controller: _bio,
          decoration: const InputDecoration(labelText: 'Bio (optional)'),
          maxLength: 500,
          maxLines: 3,
          minLines: 1,
        ),
        Text('Your vibe', style: labelStyle),
        ChipMultiSelect<RoleTag>(
          options: RoleTag.values,
          labelOf: (t) => t.label,
          selected: _roleTags,
          onChanged: (s) => setState(() => _roleTags = s),
        ),
        Text('Activities you enjoy', style: labelStyle),
        ChipMultiSelect<ActivityType>(
          options: ActivityType.values,
          labelOf: (a) => a.label,
          selected: _prefs,
          onChanged: (s) => setState(() => _prefs = s),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: _adultConfirmed,
              onChanged: (v) => setState(() => _adultConfirmed = v ?? false),
              title: const Text("I'm 18 or older"),
              subtitle: const Text('Qmate is for adults only.'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _acceptTerms,
              onChanged: (v) => setState(() => _acceptTerms = v ?? false),
              title: const Text('I agree to the Terms of Use and Privacy Policy'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            LegalLinks(
              onOpenTerms: () => openLegalPage(context, termsUrl),
              onOpenPrivacy: () => openLegalPage(context, privacyPolicyUrl),
            ),
          ],
        ),
      ],
    );
  }
}
