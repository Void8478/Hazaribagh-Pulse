import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String _normalizedDeleteErrorMessage(Object? rawError) {
  final text = rawError?.toString().trim() ?? '';
  if (text.isEmpty) {
    return 'Failed to delete account.';
  }

  final lower = text.toLowerCase();
  if (lower.contains('invalid jwt') ||
      lower.contains('jwt') ||
      lower.contains('401')) {
    return 'Your session has expired. Please log in again and retry account deletion.';
  }

  return text;
}

Future<void> _routeToLogin(GoRouter router) async {
  final supabase = Supabase.instance.client;
  try {
    await supabase.auth.signOut();
  } catch (_) {
    // Ignore local sign-out issues here; routing to login is still safe.
  }

  router.go('/login');
}

Future<void> deleteAccountPermanently(BuildContext context) async {
  final supabase = Supabase.instance.client;
  final session = supabase.auth.currentSession;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final colorScheme = Theme.of(context).colorScheme;
  final navigator = Navigator.of(context, rootNavigator: true);
  final router = GoRouter.of(context);

  if (session == null) {
    messenger?.showSnackBar(
      SnackBar(
        content: const Text('Your session has expired. Please log in again.'),
        backgroundColor: colorScheme.error,
      ),
    );
    return;
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Deleting your account permanently...',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ),
          ],
        ),
      );
    },
  );

  try {
    await supabase.functions.invoke(
      'delete-account',
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    try {
      await supabase.auth.signOut();
    } catch (_) {
      // The account may already be gone on the server; still continue locally.
    }

    if (context.mounted) {
      navigator.pop();
      router.go('/login');
    }

    messenger?.showSnackBar(
      SnackBar(
        content: const Text('Your account was permanently deleted.'),
        backgroundColor: colorScheme.primary,
      ),
    );
  } on FunctionException catch (error) {
    if (context.mounted) {
      navigator.pop();
    }

    final message = _normalizedDeleteErrorMessage(
      error.details ?? error.reasonPhrase,
    );

    if (message.toLowerCase().contains('session has expired')) {
      await _routeToLogin(router);
    }

    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
      ),
    );
  } catch (error) {
    if (context.mounted) {
      navigator.pop();
    }

    final message = _normalizedDeleteErrorMessage(error);

    if (message.toLowerCase().contains('session has expired')) {
      await _routeToLogin(router);
    }

    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
      ),
    );
  }
}
