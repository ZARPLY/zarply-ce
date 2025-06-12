import 'package:flutter/material.dart';
import '../services/password_strength_service.dart';

class PasswordStrengthProvider extends ChangeNotifier {
  PasswordStrengthResult _result = PasswordStrengthService.evaluatePassword('');

  PasswordStrengthResult get result => _result;
  PasswordStrength get strength => _result.strength;
  double get score => _result.score;
  String get message => _result.message;
  List<String> get suggestions => _result.suggestions;
  PasswordStrengthCriteria get criteria => _result.criteria;

  void evaluatePassword(String password) {
    _result = PasswordStrengthService.evaluatePassword(password);
    notifyListeners();
  }

  void reset() {
    _result = PasswordStrengthService.evaluatePassword('');
    notifyListeners();
  }

  Color get strengthColor {
    switch (_result.strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.lightGreen;
      case PasswordStrength.veryStrong:
        return Colors.green;
    }
  }

  List<Color> get progressColors {
    switch (_result.strength) {
      case PasswordStrength.weak:
        return <Color>[Colors.red];
      case PasswordStrength.medium:
        return <Color>[Colors.red, Colors.orange];
      case PasswordStrength.strong:
        return <Color>[Colors.red, Colors.orange, Colors.lightGreen];
      case PasswordStrength.veryStrong:
        return <Color>[
          Colors.red,
          Colors.orange,
          Colors.lightGreen,
          Colors.green,
        ];
    }
  }

  int get progressLevel {
    switch (_result.strength) {
      case PasswordStrength.weak:
        return 1;
      case PasswordStrength.medium:
        return 2;
      case PasswordStrength.strong:
        return 3;
      case PasswordStrength.veryStrong:
        return 4;
    }
  }
}
