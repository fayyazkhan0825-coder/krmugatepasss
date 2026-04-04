import 'package:flutter/material.dart';
import '../../services/phone_auth_service.dart';

class PhoneVerificationScreen extends StatefulWidget {
  // For web: prevents back navigation during verification
  final String phoneNumber;
  final bool isLinking;

  const PhoneVerificationScreen({super.key, 
    required this.phoneNumber,
    this.isLinking = false,
  });

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final PhoneAuthService _phoneAuthService = PhoneAuthService();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  String? _error;
  int _secondsRemaining = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _sendOTP();
    _startTimer();
  }

  Future<void> _sendOTP() async {
    try {
      setState(() => _isLoading = true);
      await _phoneAuthService.sendOTP(widget.phoneNumber);
      setState(() => _error = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to ${widget.phoneNumber}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOTP() async {
    try {
      setState(() => _isResending = true);
      await _phoneAuthService.resendOTP(widget.phoneNumber);
      setState(() {
        _error = null;
        _secondsRemaining = 30;
        _canResend = false;
      });
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        _startTimer();
      } else if (mounted) {
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      setState(() => _error = 'Please enter OTP');
      return;
    }

    if (_otpController.text.length != 6) {
      setState(() => _error = 'OTP must be 6 digits');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (widget.isLinking) {
        await _phoneAuthService.confirmPhoneLinkWithOTP(_otpController.text);
      } else {
        await _phoneAuthService.verifyOTP(_otpController.text);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
        appBar: AppBar(
          title: const Text('Verify Phone Number'),
          elevation: 0,
          centerTitle: true,
        ),
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
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 100,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.phone_in_talk_outlined,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Enter Verification Code',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a 6-digit code to\n${widget.phoneNumber}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            border:
                                Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        enabled: !_isLoading,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineLarge,
                        decoration: InputDecoration(
                          hintText: '000000',
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 16,
                          ),
                        ),
                        onChanged: (value) {
                          if (value.length == 6) {
                            FocusScope.of(context).unfocus();
                          }
                          setState(() => _error = null);
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed:
                              _isLoading ? null : _verifyOTP,
                          child: _isLoading
                              ? const CircularProgressIndicator.adaptive()
                              : const Text('Verify OTP'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!_canResend)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Resend OTP in ',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              '$_secondsRemaining s',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        )
                      else
                        TextButton(
                          onPressed: _isResending ? null : _resendOTP,
                          child: _isResending
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      theme.colorScheme.primary,
                                    ),
                                  ),
                                )
                              : const Text('Resend OTP'),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Having trouble? Check your SMS or spam folder',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
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
