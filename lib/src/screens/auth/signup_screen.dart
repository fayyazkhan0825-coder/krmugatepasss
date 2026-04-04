import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import '../../../main.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import 'phone_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _roomNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  UserRole _selectedRole = UserRole.student;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _roomNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final phoneNumber = _phoneController.text.trim();
      final hasPhone = phoneNumber.isNotEmpty;

      final appUser = await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: _selectedRole,
        roomNumber: _roomNumberController.text.trim().isEmpty
            ? null
            : _roomNumberController.text.trim(),
        phone: hasPhone ? phoneNumber : null,
      );

      if (!mounted) return;

      // If phone number provided, navigate to verification screen (mobile only)
      if (hasPhone && appUser != null && !kIsWeb) {
        final formatPhoneNumber =
            phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';

        final isVerified = await Navigator.of(context).push<bool?>(
          MaterialPageRoute(
            builder: (_) =>
                PhoneVerificationScreen(phoneNumber: formatPhoneNumber),
          ),
        );

        if (!mounted) return;

        // If verification successful, update Firestore
        if (isVerified == true) {
          try {
            await authService.updatePhoneVerificationStatus(appUser.id);
          } catch (e) {
            // Continue even if update fails
            print('Failed to update verification status: $e');
          }
        }
      } else if (hasPhone && appUser != null && kIsWeb) {
        // Web: Show message that phone verification is not available
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone verification is only available on mobile devices. Account created without phone verification.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RootRouter()),
      );
    } catch (e) {
      setState(() {
        _error = 'Signup failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.14),
                  theme.colorScheme.primary.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _AuthHeader(
                      title: 'Create account',
                      subtitle:
                          'Choose your role and sign up with your institute email',
                      icon: Icons.person_add_alt_1_outlined,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_error != null) ...[
                              _ErrorBanner(message: _error!),
                              const SizedBox(height: 12),
                            ],
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  DropdownButtonFormField<UserRole>(
                                    decoration: const InputDecoration(
                                      labelText: 'Role',
                                      prefixIcon:
                                          Icon(Icons.badge_outlined),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: UserRole.student,
                                        child: Text('Student'),
                                      ),
                                      DropdownMenuItem(
                                        value: UserRole.warden,
                                        child: Text('Warden'),
                                      ),
                                      DropdownMenuItem(
                                        value: UserRole.guard,
                                        child: Text('Guard'),
                                      ),
                                    ],
                                    initialValue: _selectedRole,
                                    onChanged: _isLoading
                                        ? null
                                        : (value) {
                                            if (value == null) return;
                                            setState(() {
                                              _selectedRole = value;
                                            });
                                          },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Full Name',
                                      prefixIcon:
                                          Icon(Icons.person_outline),
                                    ),
                                    textInputAction: TextInputAction.next,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon:
                                          Icon(Icons.email_outlined),
                                    ),
                                    keyboardType:
                                        TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter email';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _roomNumberController,
                                          decoration: const InputDecoration(
                                            labelText: 'Room (optional)',
                                            prefixIcon: Icon(
                                              Icons.room_outlined,
                                            ),
                                          ),
                                          textInputAction:
                                              TextInputAction.next,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: !kIsWeb
                                          ? TextFormField(
                                              controller: _phoneController,
                                              decoration: const InputDecoration(
                                                labelText: 'Phone (optional)',
                                                prefixIcon: Icon(
                                                  Icons.phone_outlined,
                                                ),
                                              ),
                                              keyboardType:
                                                  TextInputType.phone,
                                              textInputAction:
                                                  TextInputAction.next,
                                            )
                                          : Container(
                                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.phone_disabled, color: Colors.grey),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      'Phone verification not available on web. Use mobile app for full features.',
                                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon:
                                          const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword
                                            ? 'Show password'
                                            : 'Hide password',
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.next,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller:
                                        _confirmPasswordController,
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
                                      prefixIcon:
                                          const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        tooltip: _obscureConfirmPassword
                                            ? 'Show password'
                                            : 'Hide password',
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    obscureText: _obscureConfirmPassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) {
                                      if (!_isLoading) _submit();
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please confirm password';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 50,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _submit,
                                child: _isLoading
                                    ? const CircularProgressIndicator.adaptive()
                                    : const Text('Create account'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context)
                                          .pushReplacement(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const LoginScreen(),
                                        ),
                                      );
                                    },
                              child: const Text('I already have an account'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Your dashboard will match the role saved in Firestore.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _AuthHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Image.asset(
          'assets/krmu_logo.png',
          height: 86,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 14),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}