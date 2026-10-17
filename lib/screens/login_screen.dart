
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:my_manager/screens/signup_screen.dart';
import 'package:my_manager/screens/forgot_password_screen.dart';
import 'package:my_manager/screens/home_screen.dart';
import 'package:my_manager/services/auth_service.dart';
import 'package:my_manager/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isPasswordVisible = false;
  bool isLoading = false;

  final TextEditingController emailController =
  TextEditingController();
  final TextEditingController passwordController =
  TextEditingController();

  final AuthService authService = AuthService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Email and Password Login
  Future<void> _login() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await authService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('লগইন সফল হয়েছে!'),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          message = 'ইমেইল অথবা পাসওয়ার্ড সঠিক নয়।';
          break;
        case 'invalid-email':
          message = 'সঠিক ইমেইল ঠিকানা লিখুন।';
          break;
        case 'too-many-requests':
          message = 'অনেকবার চেষ্টা হয়েছে। পরে আবার চেষ্টা করুন।';
          break;
        case 'network-request-failed':
          message = 'ইন্টারনেট সংযোগ পরীক্ষা করুন।';
          break;
        case 'operation-not-allowed':
          message = 'Firebase Console-এ Email/Password চালু করুন।';
          break;
        default:
          message = 'লগইন করা যায়নি। আবার চেষ্টা করুন।';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('একটি সমস্যা হয়েছে। আবার চেষ্টা করুন।'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Google Sign-In
  Future<void> _googleLogin() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      await authService.signInWithGoogle();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google login সফল হয়েছে!'),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      final message = switch (e.code) {
        'account-exists-with-different-credential' =>
        'এই ইমেইলে অন্য login পদ্ধতিতে অ্যাকাউন্ট আছে।',
        'network-request-failed' =>
        'ইন্টারনেট সংযোগ পরীক্ষা করুন।',
        'operation-not-allowed' =>
        'Firebase Console-এ Google provider চালু করুন।',
        _ => 'Google login সম্পন্ন হয়নি। আবার চেষ্টা করুন।',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google login করা যায়নি। আবার চেষ্টা করুন।',
          ),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Forgot Password Navigation
  void _openForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ForgotPasswordScreen(),
      ),
    );
  }

  // Signup Navigation
  void _openSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SignupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'স্বাগতম!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'আপনার My Manager অ্যাকাউন্টে লগইন করুন',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Email Field
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'ইমেইল (Email)',
                      hintText: 'admin@gmail.com',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: AppColors.textMuted,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'ইমেইল লিখুন';
                      }

                      final emailPattern =
                      RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');

                      if (!emailPattern.hasMatch(value.trim())) {
                        return 'সঠিক ইমেইল লিখুন';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // Password Field
                  TextFormField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!isLoading) _login();
                    },
                    decoration: InputDecoration(
                      labelText: 'পাসওয়ার্ড (Password)',
                      hintText: '••••••',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.textMuted,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'পাসওয়ার্ড লিখুন';
                      }

                      if (value.length < 6) {
                        return 'কমপক্ষে ৬ অক্ষরের পাসওয়ার্ড দিন';
                      }

                      return null;
                    },
                  ),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed:
                      isLoading ? null : _openForgotPassword,
                      child: const Text('পাসওয়ার্ড ভুলে গেছেন?'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Email Login Button
                  ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: isLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'লগইন করুন',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Divider
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('অথবা'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Google Login Button
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : _googleLogin,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(
                      Icons.g_mobiledata,
                      size: 30,
                    ),
                    label: const Text(
                      'Google দিয়ে Login করুন',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Signup Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(
                        child: Text('অ্যাকাউন্ট নেই?'),
                      ),
                      TextButton(
                        onPressed: isLoading ? null : _openSignup,
                        child: const Text(
                          'Sign Up করুন',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
