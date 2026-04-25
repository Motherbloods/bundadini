import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'domain/providers/auth_provider.dart';
import 'domain/providers/patient_provider.dart';
import 'domain/providers/examination_provider.dart';
import 'domain/providers/rules_provider.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('id_ID', null);

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
      scaffoldMessengerKey: rootScaffoldMessengerKey,
    );
  }
}
