import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fyp_flutter_app/screens/main_screen.dart';
import 'package:fyp_flutter_app/screens/splash_page.dart';
import 'package:fyp_flutter_app/screens/permission_denied_page.dart';
import 'package:fyp_flutter_app/screens/vehicle_list_screen.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/donation_service.dart';
import 'package:provider/provider.dart';
import 'theme/app_buttons.dart';
import 'theme/app_icons.dart';


Future<void> main() async {
  await dotenv.load();
  runApp(
    ChangeNotifierProvider(
      create: (_) => TipService()..init(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});
   
  @override
  State<MainApp> createState() =>  _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final _navKey = GlobalKey<NavigatorState>();
  StreamSubscription<void>? _thanks;
  
  @override
  void initState() {
    super.initState();
    _thanks = context.read<TipService>().onThanks.listen((_) {
      final ctx = _navKey.currentContext;
      if (ctx == null) return;
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.thanks),
          content: Text(AppLocalizations.of(context)!.thanksContent),
          actions: [
            AppPrimaryButton(
                icon: AppIcons.refresh,
                label: AppLocalizations.of(context)!.close,
                onPressed: () =>
                    Navigator.pop(ctx),
              ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _thanks?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    

    return MaterialApp(
      navigatorKey: _navKey, 
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