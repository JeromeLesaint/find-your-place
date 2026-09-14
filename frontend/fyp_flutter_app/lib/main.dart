import 'package:flutter/material.dart';
import 'package:fyp_flutter_app/screens/main_screen.dart';
import 'package:fyp_flutter_app/screens/splash_page.dart';
import 'package:fyp_flutter_app/screens/permission_denied_page.dart';
import 'package:fyp_flutter_app/screens/vehicle_list_screen.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {
  await dotenv.load();
  runApp( const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});
   
  @override
  State<MainApp> createState() =>  _MainAppState();
}

class _MainAppState extends State<MainApp> {
  
  @override
  Widget build(BuildContext context) {
    

    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [
      Locale('fr'), // Only French
      ],
      locale: const Locale('fr'), // Force French locale
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/home': (context) => const MainScreen(),
        '/permission-denied': (context) => const PermissionDeniedPage(),
        '/vehicle-list': (context) => const VehicleListScreen(),
      },
    );
  }
}