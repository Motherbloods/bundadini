import 'package:flutter/material.dart';

class PatientProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _patients = [];

  List<Map<String, dynamic>> get patients => _patients;

  void addPatient(Map<String, dynamic> patient) {
    _patients.add(patient);
    notifyListeners();
  }

  void removePatient(int index) {
    if (index >= 0 && index < _patients.length) {
      _patients.removeAt(index);
      notifyListeners();
    }
  }

  void clearPatients() {
    _patients.clear();
    notifyListeners();
  }
}
