/// Shared form-field validators used across Login, Register, and other
/// forms. All return `null` when the value is valid, or a user-facing
/// error message otherwise.
class Validators {
  Validators._();

  static final _emailRegex = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Name is required';
    if (v.length < 2) return 'Name must be at least 2 characters';
    if (v.length > 50) return 'Name must be under 50 characters';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    if (v.length > 64) return 'Password is too long';
    final hasLetter = v.contains(RegExp(r'[A-Za-z]'));
    final hasNumber = v.contains(RegExp(r'\d'));
    if (!hasLetter || !hasNumber) {
      return 'Use letters and at least one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? notEmpty(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? positiveInt(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    final n = int.tryParse(value.trim());
    if (n == null) return '$field must be a number';
    if (n < 0) return '$field cannot be negative';
    return null;
  }
}

/// Returns a strength score (0..4) for the given password.
/// 0 = empty/very weak, 4 = strong.
int passwordStrength(String value) {
  if (value.isEmpty) return 0;
  int score = 0;
  if (value.length >= 6) score++;
  if (value.length >= 10) score++;
  if (value.contains(RegExp(r'[A-Z]')) && value.contains(RegExp(r'[a-z]'))) {
    score++;
  }
  if (value.contains(RegExp(r'\d'))) score++;
  if (value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\\[\];]'))) score++;
  return score.clamp(0, 4);
}
