import 'package:flutter/material.dart';
import '../services/location_permission_service.dart';
import '../theme/app_buttons.dart';
import '../theme/app_icons.dart';
import '../l10n/app_localizations.dart';

class PermissionDeniedPage extends StatelessWidget {
  const PermissionDeniedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final result = ModalRoute.of(context)!.settings.arguments
        as LocationPermissionResult?;

    final String message;
    final String buttonLabel;
    final VoidCallback? onPressed;

    switch (result) {
      case LocationPermissionResult.serviceDisabled:
        message = AppLocalizations.of(context)!.locationServiceDisabled;
        buttonLabel = AppLocalizations.of(context)!.activateLocation;
        onPressed = () => LocationPermissionService.openLocationSettings();
        break;

      case LocationPermissionResult.deniedForever:
        message = AppLocalizations.of(context)!.locationPermissionDeniedForever;
        buttonLabel = AppLocalizations.of(context)!.openSettings;
        onPressed = () => LocationPermissionService.openAppSettings();
        break;

      case LocationPermissionResult.denied:
      default:
        message =AppLocalizations.of(context)!.locationPermissionDenied ;
        buttonLabel = AppLocalizations.of(context)!.tryAgain;
        onPressed = () => Navigator.of(context).pushReplacementNamed('/');
        break;
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(AppIcons.locationOff, size: 64, color: Colors.redAccent),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              AppSecondaryButton(
                icon: AppIcons.settings,
                label: buttonLabel,
                onPressed: onPressed,
              ),
              const SizedBox(height: 12),
              AppPrimaryButton(
                icon: AppIcons.refresh,
                label: AppLocalizations.of(context)!.reverify,
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
