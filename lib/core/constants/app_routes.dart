class AppRoutes {
  AppRoutes._();

  // Auth
  static const String splash = '/';
  static const String login = '/login';

  // Kader
  static const String kaderHome = '/kader/home';
  static const String addPatient = '/kader/patients/add';
  static const String patientDetail = '/kader/patients/:patientId';
  static const String editPatient = '/kader/patients/:patientId/edit';
  static const String examinationStepper = '/kader/patients/:patientId/examine';
  static const String examinationResult = '/kader/examine/result';
  static const String examinationHistory = '/kader/patients/:patientId/history';

  // Bidan
  static const String bidanDashboard = '/bidan/dashboard';
  static const String kaderList = '/bidan/kaders';
  static const String addKader = '/bidan/kaders/add';
  static const String kaderDetailBidan = '/bidan/kaders/:kaderId';
  static const String allPatients = '/bidan/patients';
  static const String patientDetailBidan = '/bidan/patients/:patientId';
  static const String exportScreen = '/bidan/export';
  static const String bidanProfile = '/bidan/profile';
}
