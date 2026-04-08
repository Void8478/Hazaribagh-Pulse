import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_provider.dart';
import '../../../core/utils/phone_formatter.dart';

class EmailSignupScreen extends ConsumerStatefulWidget {
  const EmailSignupScreen({super.key});

  @override
  ConsumerState<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends ConsumerState<EmailSignupScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '+91 ');
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _signup() {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ref.read(authProvider.notifier).signUpWithEmail(
          _fullNameController.text.trim(),
          _emailController.text.trim(),
          phone,
          _passwordController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    // Listen for errors and verification state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null &&
          (previous == null || previous.error != next.error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
      // Navigation to verification screen is driven by the router.
    });

    // --- NORMAL SIGNUP FORM ---
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join Pulse',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up with email to discover and review local places.',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      value == null || value.isEmpty
                          ? 'Please enter your full name'
                          : null,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value == null || value.isEmpty
                          ? 'Please enter your email'
                          : null,
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                    hintText: '+91 98765 43210',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [IndianPhoneNumberFormatter()],
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        value == '+91 ') {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 15) {
                      return 'Please enter a valid 10-digit number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                  obscureText: !_passwordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_reset),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_confirmVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _confirmVisible = !_confirmVisible),
                    ),
                  ),
                  obscureText: !_confirmVisible,
                  validator: (value) =>
                      value == null || value.isEmpty
                          ? 'Please confirm your password'
                          : null,
                ),
                const SizedBox(height: 32),

                // Sign Up button
                if (authState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  FilledButton(
                    onPressed: _signup,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Create Account',
                        style: TextStyle(fontSize: 16)),
                  ),

                const SizedBox(height: 24),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => context.pushReplacement('/email-login'),
                      child: const Text('Log In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
