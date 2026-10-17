import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_manager/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _authService.resetPassword(
        email: _emailController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'সম্ভব হলে এই ইমেইলে পাসওয়ার্ড রিসেটের নির্দেশনা পাঠানো হয়েছে।',
          ),
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      final message = switch (e.code) {
        'invalid-email' => 'সঠিক ইমেইল লিখুন।',
        'too-many-requests' => 'অনেকবার চেষ্টা হয়েছে। পরে চেষ্টা করুন।',
        _ => 'রিকভারি ইমেইল পাঠানো যায়নি। ইমেইল ও ইন্টারনেট পরীক্ষা করুন।',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('পাসওয়ার্ড ভুলে গেছেন?')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Icon(Icons.mark_email_unread_outlined, size: 64),
                const SizedBox(height: 20),
                const Text(
                  'পাসওয়ার্ড রিসেট করুন',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'আপনার অ্যাকাউন্টের ইমেইল লিখুন। রিসেট করার নির্দেশনা পাঠানো হবে।',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'ইমেইল',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'ইমেইল লিখুন';
                    }
                    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$')
                        .hasMatch(value.trim())) {
                      return 'সঠিক ইমেইল লিখুন';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _sendResetLink,
                  child: _loading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Reset Link পাঠান'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}