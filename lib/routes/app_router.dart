import 'package:bundadini/presentation/auth/login_screen.dart';
import 'package:bundadini/presentation/auth/splash_screen.dart';
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
          ]);
}
