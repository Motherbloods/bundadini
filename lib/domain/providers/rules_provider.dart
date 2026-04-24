import 'package:flutter/foundation.dart';
import '../../data/models/rule_model.dart';
import '../../data/repositories/rule_repository.dart';

class RulesProvider extends ChangeNotifier {
  final RuleRepository _repo = RuleRepository();

  List<RuleModel> _rules = [];
  bool _isLoaded = false;

  List<RuleModel> get rules => _rules;
  bool get isLoaded => _isLoaded;

  RulesProvider() {
    fetchRules();
  }

  Future<void> fetchRules() async {
    try {
      _rules = await _repo.fetchActiveRules();
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('RulesProvider error: $e');
    }
  }
}
