import 'package:material_ui/material_ui.dart';

/// Shared layout for login and register: heading, fields, error, submit button.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
    required this.busy,
    this.error,
    this.footer,
  });

  final String title;
  final String subtitle;
  final List<Widget> fields;
  final String submitLabel;

  /// Null disables the submit button (e.g. required boxes unchecked).
  final VoidCallback? onSubmit;
  final bool busy;
  final String? error;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('qmate', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                    const SizedBox(height: 8),
                    Text(title, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    for (final field in fields) Padding(padding: const EdgeInsets.only(bottom: 16), child: field),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(error!, style: TextStyle(color: theme.colorScheme.error)),
                      ),
                    FilledButton(
                      onPressed: busy ? null : onSubmit,
                      child: busy
                          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(submitLabel),
                    ),
                    if (footer != null) ...[const SizedBox(height: 8), footer!],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
