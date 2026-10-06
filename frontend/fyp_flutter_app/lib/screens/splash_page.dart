import 'dart:core';

import 'package:flutter/material.dart';
import '../services/location_permission_service.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';


class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  String _statusText = '';
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  Timer? _timer;
  bool _isClosing = false;
  Duration displayDuration = const Duration(seconds: 3);
  Duration fadeDuration = const Duration(milliseconds: 400);
  bool dismissOnTap = true;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: fadeDuration,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    _timer = Timer(displayDuration, _close);
    // On lance la vérification après le premier frame pour être sûr
    // que le contexte de navigation est prêt.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
    
  }

  Future<void> _initApp() async {

    _statusText = AppLocalizations.of(context)!.initializing;

    // Petit délai pour laisser le splash visible un minimum de temps
    // (évite un flash trop rapide si tout va vite).
    final minimumDelay = Future.delayed(const Duration(seconds: 2));

    setState(() => _statusText = AppLocalizations.of(context)!.verifyLocation);

    final result = await LocationPermissionService.checkAndRequestPermission();

    // On attend que le délai minimum soit écoulé avant de naviguer.
    await minimumDelay;

    if (!mounted) return;

    switch (result) {
      case LocationPermissionResult.granted:
        Navigator.of(context).pushReplacementNamed('/home');
        break;

      case LocationPermissionResult.serviceDisabled:
      case LocationPermissionResult.denied:
      case LocationPermissionResult.deniedForever:
        Navigator.of(context).pushReplacementNamed(
          '/permission-denied',
          arguments: result,
        );
        break;
    }
  }

  void _close() {
    if (_isClosing || !mounted) return;
    _isClosing = true;

    _timer?.cancel(); // au cas où on ferme via le tap avant l'échéance
    _controller.reverse().then((_) {
      
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: dismissOnTap ? _close : null,
      child: Scaffold(
        body: FadeTransition(
          opacity: _opacity,
          child: Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/find_your_place_logo.png', width: 300, height: 300),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _statusText,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
