import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_provider.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../utils/validators.dart';
import '../home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await AuthService.instance.login(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      rememberMe: _rememberMe,
    );
    if (!mounted) return;

    if (result.isSuccess) {
      context.read<AppProvider>().setCurrentUser(result.user!);
      
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        HomeScreen.routeName,
        (_) => false,
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: _buildHeader(),
                      ),
                      const SizedBox(height: 36),
                      FadeInUp(
                        delay: const Duration(milliseconds: 150),
                        child: _buildEmailField(),
                      ),
                      const SizedBox(height: 14),
                      FadeInUp(
                        delay: const Duration(milliseconds: 220),
                        child: _buildPasswordField(),
                      ),
                      const SizedBox(height: 10),
                      FadeInUp(
                        delay: const Duration(milliseconds: 280),
                        child: _buildRememberRow(),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        FadeIn(child: _buildErrorBanner(_errorMessage!)),
                      ],
                      const SizedBox(height: 24),
                      FadeInUp(
                        delay: const Duration(milliseconds: 340),
                        child: _buildLoginButton(),
                      ),
                      const SizedBox(height: 24),
                      FadeIn(
                        delay: const Duration(milliseconds: 420),
                        child: _buildRegisterRow(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              size: 44,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Welcome back',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sign in to continue managing your medicines',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      );

  Widget _buildEmailField() => TextFormField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        textInputAction: TextInputAction.next,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: const InputDecoration(
          labelText: 'Email address',
          prefixIcon: Icon(Icons.alternate_email_rounded),
        ),
        validator: Validators.email,
      );

  Widget _buildPasswordField() => TextFormField(
        controller: _passwordCtrl,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
        style: const TextStyle(color: AppTheme.textPrimary),
        onFieldSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        validator: (v) =>
            (v == null || v.isEmpty) ? 'Password is required' : null,
      );

  Widget _buildRememberRow() => Row(
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: _rememberMe,
              activeColor: AppTheme.primary,
              checkColor: Colors.black,
              onChanged: (v) => setState(() => _rememberMe = v ?? true),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Keep me signed in',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Password recovery is not enabled in this offline build.',
                  ),
                ),
              );
            },
            child: const Text('Forgot?'),
          ),
        ],
      );

  Widget _buildErrorBanner(String message) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppTheme.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppTheme.danger, fontSize: 13),
              ),
            ),
          ],
        ),
      );

  Widget _buildLoginButton() => SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.black,
                  ),
                )
              : const Text('Sign in', style: TextStyle(fontSize: 16)),
        ),
      );

  Widget _buildRegisterRow() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Don't have an account?",
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.pushNamed(
                      context,
                      RegisterScreen.routeName,
                    ),
            child: const Text('Create one'),
          ),
        ],
      );
}
