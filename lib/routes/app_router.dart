// lib/routes/app_router.dart

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
              path: '/',
              builder: (context, state) => const Scaffold(
                body: Center(
                  child: Text('Bunda Dini App'),
                ),
              ),
            ),
          ]);
}
