import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'domain/providers/auth_provider.dart';
import 'domain/providers/patient_provider.dart';
import 'domain/providers/examination_provider.dart';
import 'domain/providers/rules_provider.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => ExaminationProvider()),
        ChangeNotifierProvider(create: (_) => RulesProvider()),
      ],
      child: const BundaDiniApp(),
    ),
  );
}

class BundaDiniApp extends StatelessWidget {
  const BundaDiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bunda Dini',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
