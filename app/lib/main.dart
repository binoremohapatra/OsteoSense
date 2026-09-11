import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/screening_provider.dart';
import 'providers/settings_provider.dart';
import 'services/firebase_messaging_service.dart';
import 'services/notification_service.dart';
import 'services/notification_scheduler.dart';
import 'router/app_router.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase Messaging
  final firebaseMessagingService = FirebaseMessagingService();
  await firebaseMessagingService.initialize();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Initialize notification scheduler
  final notificationScheduler = NotificationScheduler();

  // Initialize settings
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  runApp(EasyLocalization(
    supportedLocales: const [
      Locale('en'),
      Locale('hi'),
      Locale('bn'),
      Locale('ta'),
      Locale('te'),
      Locale('mr'),
      Locale('gu'),
      Locale('kn'),
      Locale('ml'),
      Locale('pa'),
      Locale('as'),
      Locale('or'),
    ],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    child: JointSaathiApp(settingsProvider: settingsProvider),
  ));
}

class JointSaathiApp extends StatelessWidget {
  final SettingsProvider settingsProvider;
  
  const JointSaathiApp({super.key, required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => ScreeningProvider()),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: MaterialApp.router(
        title: 'JointSaathi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(
          textTheme: GoogleFonts.interTextTheme(AppTheme.lightTheme.textTheme),
        ),
        darkTheme: AppTheme.darkTheme.copyWith(
          textTheme: GoogleFonts.interTextTheme(AppTheme.darkTheme.textTheme),
        ),
        themeMode: ThemeMode.system,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        routerConfig: appRouter,
      ),
    );
  }
}
