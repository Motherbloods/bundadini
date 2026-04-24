import 'package:bundadini/presentation/auth/login_screen.dart';
import 'package:bundadini/presentation/auth/splash_screen.dart';
import '../presentation/kader/dashboard/kader_home_screen.dart';
import '../presentation/kader/patients/add_patient_screen.dart';
import '../presentation/kader/patients/patient_detail_screen.dart';
import '../presentation/kader/patients/edit_patient_screen.dart';
// import '../presentation/kader/examination/examination_stepper_screen.dart';
// import '../presentation/kader/examination/examination_result_screen.dart';
// import '../presentation/kader/examination/examination_history_screen.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => GoRouter(
          navigatorKey: _rootNavigatorKey,
          debugLogDiagnostics: true,
          initialLocation: AppRoutes.splash,
          routes: [
            GoRoute(
              path: AppRoutes.splash,
              builder: (_, __) => const SplashScreen(),
            ),
            GoRoute(
              path: AppRoutes.login,
              builder: (_, __) => const LoginScreen(),
            ),

            // Kader

            GoRoute(
              path: AppRoutes.kaderHome,
              builder: (_, __) => const KaderHomeScreen(),
            ),
            GoRoute(
              path: AppRoutes.addPatient,
              builder: (_, __) => const AddPatientScreen(),
            ),
            GoRoute(
              path: '/kader/patients/:patientId',
              builder: (_, state) => PatientDetailScreen(
                patientId: state.pathParameters['patientId']!,
              ),
            ),
            GoRoute(
              path: '/kader/patients/:patientId/edit',
              builder: (_, state) => EditPatientScreen(
                patientId: state.pathParameters['patientId']!,
              ),
            ),
            // GoRoute(
            //   path: '/kader/patients/:patientId/examine',
            //   builder: (_, state) => ExaminationStepperScreen(
            //     patientId: state.pathParameters['patientId']!,
            //   ),
            // ),
            // GoRoute(
            //   path: AppRoutes.examinationResult,
            //   builder: (_, state) {
            //     final examId = state.extra as String;
            //     return ExaminationResultScreen(examinationId: examId);
            //   },
            // ),
            // GoRoute(
            //   path: '/kader/patients/:patientId/history',
            //   builder: (_, state) => ExaminationHistoryScreen(
            //     patientId: state.pathParameters['patientId']!,
            //   ),
            // ),
          ]);
}
