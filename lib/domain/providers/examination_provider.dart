import 'package:flutter/material.dart';

class ExaminationProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _examinations = [];

  List<Map<String, dynamic>> get examinations => _examinations;

  void addExamination(Map<String, dynamic> data) {
    _examinations.add(data);
    notifyListeners();
  }

  void removeExamination(int index) {
    if (index >= 0 && index < _examinations.length) {
      _examinations.removeAt(index);
      notifyListeners();
    }
  }

  void clear() {
    _examinations.clear();
    notifyListeners();
  }
}
