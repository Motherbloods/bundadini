import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_routes.dart';
import '../data/models/user_model.dart';
import '../domain/providers/auth_provider.dart';
import '../presentation/auth/splash_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/about_screen.dart';
import '../presentation/auth/privacy_screen.dart';

import '../presentation/kader/dashboard/kader_home_screen.dart';
import '../presentation/kader/patients/add_patient_screen.dart';
import '../presentation/kader/patients/patient_detail_screen.dart';
import '../presentation/kader/patients/edit_patient_screen.dart';
import '../presentation/kader/examination/examination_stepper_screen.dart';
import '../presentation/kader/examination/examination_result_screen.dart';
import '../presentation/kader/examination/examination_history_screen.dart';

import '../presentation/bidan/dashboard/bidan_dashboard_screen.dart';
import '../presentation/bidan/kader_management/kader_list_screen.dart';
import '../presentation/bidan/kader_management/add_kader_screen.dart';
import '../presentation/bidan/patients/all_patients_screen.dart';
import '../presentation/bidan/patients/patient_detail_bidan_screen.dart';
import '../presentation/bidan/reports/export_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static const _publicRoutes = [
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.about,
    AppRoutes.privacy,
  ];

  static const _sharedRoutes = [
    '/shared/examine/result',
  ];

  static GoRouter get router {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: false,
      redirect: _redirect,
      routes: [
        // Auth
        GoRoute(
          path: AppRoutes.splash,
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.about,
          builder: (_, __) => const AboutScreen(),
        ),
        GoRoute(
          path: AppRoutes.privacy,
          builder: (_, __) => const PrivacyScreen(),
        ),

        GoRoute(
          path: '/shared/examine/result',
          builder: (_, state) {
            final examId = state.extra as String;
            return ExaminationResultScreen(examinationId: examId);
          },
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
        GoRoute(
          path: '/kader/patients/:patientId/examine',
          builder: (_, state) => ExaminationStepperScreen(
            patientId: state.pathParameters['patientId']!,
          ),
        ),

        GoRoute(
          path: '/kader/patients/:patientId/history',
          builder: (_, state) => ExaminationHistoryScreen(
            patientId: state.pathParameters['patientId']!,
          ),
        ),

        // Bidan
        GoRoute(
          path: AppRoutes.bidanDashboard,
          builder: (_, __) => const BidanDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.kaderList,
          builder: (_, __) => const KaderListScreen(),
        ),
        GoRoute(
          path: AppRoutes.addKader,
          builder: (_, __) => const AddKaderScreen(),
        ),
        GoRoute(
          path: AppRoutes.allPatients,
          builder: (_, __) => const AllPatientsScreen(),
        ),
        GoRoute(
          path: AppRoutes.exportScreen,
          builder: (_, __) => const ExportScreen(),
        ),
        GoRoute(
          path: '/bidan/patients/:patientId',
          builder: (_, state) => PatientDetailBidanScreen(
            patientId: state.pathParameters['patientId']!,
          ),
        ),
        GoRoute(
          path: '/bidan/patients/:patientId/history',
          builder: (_, state) => ExaminationHistoryScreen(
            patientId: state.pathParameters['patientId']!,
          ),
        ),
      ],
    );
  }

  /// Redirect berdasarkan auth state & role
  static String? _redirect(BuildContext context, GoRouterState state) {
    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;
    final user = authProvider.currentUser;
    final location = state.matchedLocation;

    final onSplash = location == AppRoutes.splash;
    final onLogin = location == AppRoutes.login;

    final isPublic = _publicRoutes.contains(location);
    if (isPublic && !onSplash && !onLogin) return null;

    // Belum login → ke login
    if (!isLoggedIn) {
      if (onSplash || onLogin) return null;
      return AppRoutes.login;
    }

    // Sudah login tapi masih di splash/login → arahkan ke home
    if (onSplash || onLogin) {
      return user?.role == UserRole.bidan
          ? AppRoutes.bidanDashboard
          : AppRoutes.kaderHome;
    }

    // Route shared → boleh diakses semua role, skip guard
    final onSharedPage = _sharedRoutes.any((r) => location.startsWith(r));
    if (onSharedPage) return null;

    // Kader coba akses halaman bidan → redirect ke home kader
    final onBidanPage = location.startsWith('/bidan');
    if (onBidanPage && user?.role == UserRole.kader) {
      return AppRoutes.kaderHome;
    }

    // Bidan coba akses halaman kader → redirect ke dashboard bidan
    final onKaderPage = location.startsWith('/kader');
    if (onKaderPage && user?.role == UserRole.bidan) {
      return AppRoutes.bidanDashboard;
    }

    return null;
  }
}
