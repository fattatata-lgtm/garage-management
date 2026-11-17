import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/auth_provider.dart';
import 'core/nav.dart';
import 'core/settings_provider.dart';
import 'core/storage.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell.dart';
import 'widgets/motion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await Store.init();
  Api.I.configure();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final auth = AuthProvider();
  final settings = SettingsProvider();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ],
      child: const BengkelApp(),
    ),
  );

  // Pulihkan sesi setelah UI tampil (splash ditampilkan selama proses ini)
  await auth.bootstrap();
  if (auth.user != null) settings.load(authed: true);
}

class BengkelApp extends StatelessWidget {
  const BengkelApp({super.key});

  // Tema dibuat sekali agar tidak dianimasikan ulang setiap MaterialApp dibangun ulang.
  static final ThemeData _light = buildLightTheme();
  static final ThemeData _dark = buildDarkTheme();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'Self Automotive',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: _light,
      darkTheme: _dark,
      themeAnimationDuration: const Duration(milliseconds: 380),
      themeAnimationCurve: Curves.easeInOut,
      themeMode: settings.themeMode,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: !auth.ready
          ? const _Splash()
          : (auth.user != null ? const Shell() : const LoginScreen()),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: C.heroOf(context)),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Breathing(child: Icon(Icons.build_rounded, size: 56, color: Colors.white)),
              SizedBox(height: 18),
              SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
