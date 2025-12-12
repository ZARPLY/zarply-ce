import 'dart:math';

enum PasswordStrength { weak, medium, strong, veryStrong }

class PasswordStrengthCriteria {
  const PasswordStrengthCriteria({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumbers,
    required this.hasSpecialChars,
    required this.hasNoSequentialChars,
    required this.hasNoRepeatingChars,
    required this.hasMinLengthStrong,
  });
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumbers;
  final bool hasSpecialChars;
  final bool hasNoSequentialChars;
  final bool hasNoRepeatingChars;
  final bool hasMinLengthStrong;

  int get score {
    int totalScore = 0;
    if (hasMinLength) totalScore += 1;
    if (hasUppercase) totalScore += 1;
    if (hasLowercase) totalScore += 1;
    if (hasNumbers) totalScore += 1;
    if (hasSpecialChars) totalScore += 1;
    if (hasNoSequentialChars) totalScore += 1;
    if (hasNoRepeatingChars) totalScore += 1;
    if (hasMinLengthStrong) totalScore += 1;
    return totalScore;
  }

  List<String> get failedCriteria {
    final List<String> failed = <String>[];
    if (!hasMinLength) failed.add('At least 8 characters');
    if (!hasUppercase) failed.add('One uppercase letter');
    if (!hasLowercase) failed.add('One lowercase letter');
    if (!hasNumbers) failed.add('One number');
    if (!hasSpecialChars) failed.add('One special character');
    if (!hasNoSequentialChars) failed.add('Avoid sequential characters');
    if (!hasNoRepeatingChars) failed.add('Avoid repeating characters');
    if (!hasMinLengthStrong) {
      failed.add('At least 12 characters for strong password');
    }
    return failed;
  }
}

class PasswordStrengthResult {
  const PasswordStrengthResult({
    required this.strength,
    required this.criteria,
    required this.score,
    required this.message,
    required this.suggestions,
  });
  final PasswordStrength strength;
  final PasswordStrengthCriteria criteria;
  final double score;
  final String message;
  final List<String> suggestions;
}

class PasswordStrengthService {
  static const List<String> _commonPasswords = <String>[
    'password',
    '123456',
    '12345678',
    'qwerty',
    'abc123',
    'password123',
    'admin',
    'letmein',
    'welcome',
    'monkey',
  ];

  static const List<String> _sequentialPatterns = <String>[
    'abc',
    'bcd',
    'cde',
    'def',
    '123',
    '234',
    '345',
    '456',
    '567',
    '678',
    '789',
  ];

  static PasswordStrengthResult evaluatePassword(String password) {
    if (password.isEmpty) {
      return const PasswordStrengthResult(
        strength: PasswordStrength.weak,
        criteria: PasswordStrengthCriteria(
          hasMinLength: false,
          hasUppercase: false,
          hasLowercase: false,
          hasNumbers: false,
          hasSpecialChars: false,
          hasNoSequentialChars: true,
          hasNoRepeatingChars: true,
          hasMinLengthStrong: false,
        ),
        score: 0,
        message: 'Enter a password',
        suggestions: <String>['Start typing to see password requirements'],
      );
    }

    final PasswordStrengthCriteria criteria = _evaluateCriteria(password);
    final PasswordStrength strength = _calculateStrength(criteria, password);
    final double score = _calculateScore(criteria);
    final String message = _generateMessage(strength);
    final List<String> suggestions = _generateSuggestions(criteria, password);

    return PasswordStrengthResult(
      strength: strength,
      criteria: criteria,
      score: score,
      message: message,
      suggestions: suggestions,
    );
  }

  static PasswordStrengthCriteria _evaluateCriteria(String password) {
    return PasswordStrengthCriteria(
      hasMinLength: password.length >= 8,
      hasUppercase: password.contains(RegExp('[A-Z]')),
      hasLowercase: password.contains(RegExp('[a-z]')),
      hasNumbers: password.contains(RegExp('[0-9]')),
      hasSpecialChars: password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      hasNoSequentialChars: !_hasSequentialChars(password),
      hasNoRepeatingChars: !_hasRepeatingChars(password),
      hasMinLengthStrong: password.length >= 12,
    );
  }

  static bool _hasSequentialChars(String password) {
    final String lowerPassword = password.toLowerCase();
    for (final String pattern in _sequentialPatterns) {
      if (lowerPassword.contains(pattern) || lowerPassword.contains(pattern.split('').reversed.join())) {
        return true;
      }
    }
    return false;
  }

  static bool _hasRepeatingChars(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      if (password[i] == password[i + 1] && password[i + 1] == password[i + 2]) {
        return true;
      }
    }
    return false;
  }

  static PasswordStrength _calculateStrength(
    PasswordStrengthCriteria criteria,
    String password,
  ) {
    if (_isCommonPassword(password)) {
      return PasswordStrength.weak;
    }

    final int score = criteria.score;

    if (score >= 7 && criteria.hasMinLengthStrong) {
      return PasswordStrength.veryStrong;
    } else if (score >= 5 && criteria.hasMinLength) {
      return PasswordStrength.strong;
    } else if (score >= 3 && criteria.hasMinLength) {
      return PasswordStrength.medium;
    } else {
      return PasswordStrength.weak;
    }
  }

  static bool _isCommonPassword(String password) {
    final String lowerPassword = password.toLowerCase();
    return _commonPasswords.any(
      (String common) => lowerPassword.contains(common.toLowerCase()),
    );
  }

  static double _calculateScore(PasswordStrengthCriteria criteria) {
    return min(1, criteria.score / 8.0);
  }

  static String _generateMessage(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  static List<String> _generateSuggestions(
    PasswordStrengthCriteria criteria,
    String password,
  ) {
    final List<String> suggestions = <String>[];

    if (!criteria.hasMinLength) {
      suggestions.add('Use at least 8 characters');
    }
    if (!criteria.hasUppercase) {
      suggestions.add('Add uppercase letters (A-Z)');
    }
    if (!criteria.hasLowercase) {
      suggestions.add('Add lowercase letters (a-z)');
    }
    if (!criteria.hasNumbers) {
      suggestions.add('Add numbers (0-9)');
    }
    if (!criteria.hasSpecialChars) {
      suggestions.add('Add special characters (!@#%^&*)');
    }
    if (!criteria.hasNoSequentialChars) {
      suggestions.add('Avoid sequential characters (abc, 123)');
    }
    if (!criteria.hasNoRepeatingChars) {
      suggestions.add('Avoid repeating characters (aaa, 111)');
    }
    if (!criteria.hasMinLengthStrong && criteria.score >= 5) {
      suggestions.add('Use 12+ characters for very strong password');
    }

    if (_isCommonPassword(password)) {
      suggestions.insert(0, 'Avoid common passwords');
    }

    return suggestions;
  }

  static String? getPasswordHintText(PasswordStrengthResult result) {
    if (result.criteria.score >= 8) return null;

    final List<String> hints = <String>[];

    if (!result.criteria.hasMinLength) hints.add('at least 8 characters');
    if (!result.criteria.hasUppercase) hints.add('an uppercase letter');
    if (!result.criteria.hasLowercase) hints.add('a lowercase letter');
    if (!result.criteria.hasNumbers) hints.add('a number');
    if (!result.criteria.hasSpecialChars) hints.add('a special character');

    if (hints.isEmpty) return null;

    final String formattedHints = _formatNaturalLanguageList(hints);
    return 'Hint: Try adding $formattedHints.';
  }

  static String _formatNaturalLanguageList(List<String> items) {
    if (items.length == 1) return items.first;
    if (items.length == 2) return '${items[0]} and ${items[1]}';
    return '${items.sublist(0, items.length - 1).join(', ')}, and ${items.last}';
  }
}
