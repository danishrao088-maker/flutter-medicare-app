import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_provider.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../utils/validators.dart';
import '../home_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _acceptedTerms = false;
  String? _errorMessage;
  int _strength = 0;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_updateStrength);
  }

  void _updateStrength() {
    setState(() => _strength = passwordStrength(_passwordCtrl.text));
  }

  @override
  void dispose() {
    _passwordCtrl.removeListener(_updateStrength);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      setState(() => _errorMessage = 'Please accept the terms to continue.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.instance.register(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
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
          child: Stack(
            children: [
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
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
                          const SizedBox(height: 28),
                          FadeInUp(
                            delay: const Duration(milliseconds: 120),
                            child: _buildNameField(),
                          ),
                          const SizedBox(height: 14),
                          FadeInUp(
                            delay: const Duration(milliseconds: 180),
                            child: _buildEmailField(),
                          ),
                          const SizedBox(height: 14),
                          FadeInUp(
                            delay: const Duration(milliseconds: 240),
                            child: _buildPasswordField(),
                          ),
                          const SizedBox(height: 8),
                          FadeIn(child: _buildStrengthMeter()),
                          const SizedBox(height: 14),
                          FadeInUp(
                            delay: const Duration(milliseconds: 300),
                            child: _buildConfirmField(),
                          ),
                          const SizedBox(height: 14),
                          FadeInUp(
                            delay: const Duration(milliseconds: 360),
                            child: _buildTermsRow(),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            FadeIn(child: _buildErrorBanner(_errorMessage!)),
                          ],
                          const SizedBox(height: 24),
                          FadeInUp(
                            delay: const Duration(milliseconds: 420),
                            child: _buildSubmitButton(),
                          ),
                          const SizedBox(height: 18),
                          FadeIn(
                            delay: const Duration(milliseconds: 500),
                            child: _buildLoginRow(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.person_add_alt_1_rounded,
                size: 36, color: Colors.black),
          ),
          const SizedBox(height: 18),
          const Text(
            'Create your account',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Start managing your medicines today',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      );

  Widget _buildNameField() => TextFormField(
        controller: _nameCtrl,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.name],
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: const InputDecoration(
          labelText: 'Full name',
          prefixIcon: Icon(Icons.person_outline_rounded),
        ),
        validator: Validators.name,
      );

  Widget _buildEmailField() => TextFormField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
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
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.newPassword],
        style: const TextStyle(color: AppTheme.textPrimary),
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
        validator: Validators.password,
      );

  Widget _buildStrengthMeter() {
    final value = _strength / 4;
    Color color;
    String label;
    if (_strength <= 1) {
      color = AppTheme.danger;
      label = 'Weak';
    } else if (_strength == 2) {
      color = AppTheme.warning;
      label = 'Fair';
    } else if (_strength == 3) {
      color = AppTheme.info;
      label = 'Good';
    } else {
      color = AppTheme.success;
      label = 'Strong';
    }
    if (_passwordCtrl.text.isEmpty) {
      return const SizedBox(height: 16);
    }
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: AppTheme.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmField() => TextFormField(
        controller: _confirmCtrl,
        obscureText: _obscureConfirm,
        textInputAction: TextInputAction.done,
        style: const TextStyle(color: AppTheme.textPrimary),
        onFieldSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: 'Confirm password',
          prefixIcon: const Icon(Icons.lock_reset_rounded),
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirm
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined),
            onPressed: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        validator: (v) =>
            Validators.confirmPassword(v, _passwordCtrl.text),
      );

  Widget _buildTermsRow() => InkWell(
        onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _acceptedTerms,
                  activeColor: AppTheme.primary,
                  checkColor: Colors.black,
                  onChanged: (v) =>
                      setState(() => _acceptedTerms = v ?? false),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'I agree to the Terms of Service and Privacy Policy.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildSubmitButton() => SizedBox(
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
              : const Text('Create account', style: TextStyle(fontSize: 16)),
        ),
      );

  Widget _buildLoginRow() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Already have an account?',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Sign in'),
          ),
        ],
      );
}
