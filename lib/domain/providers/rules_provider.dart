// lib/domain/providers/rules_provider.dart
import 'package:flutter/material.dart';

class RulesProvider extends ChangeNotifier {
  final List<String> _rules = [];

  List<String> get rules => _rules;

  void addRule(String rule) {
    _rules.add(rule);
    notifyListeners();
  }

  void removeRule(int index) {
    if (index >= 0 && index < _rules.length) {
      _rules.removeAt(index);
      notifyListeners();
    }
  }

  void clearRules() {
    _rules.clear();
    notifyListeners();
  }
}
