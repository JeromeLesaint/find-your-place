import 'package:geolocator/geolocator.dart';

/// Résultat possible de la vérification de permission de géolocalisation.
enum LocationPermissionResult {
  /// Le service de localisation est désactivé sur l'appareil (GPS off).
  serviceDisabled,

  /// La permission a été refusée par l'utilisateur (mais peut être redemandée).
  denied,

  /// La permission a été refusée définitivement (l'utilisateur doit aller
  /// dans les réglages de l'application pour l'activer).
  deniedForever,

  /// La permission est accordée (précise ou approximative).
  granted,
}

/// Service centralisant toute la logique liée à la permission de
/// géolocalisation : vérification de l'état actuel + demande à l'utilisateur.
class LocationPermissionService {
  /// Vérifie l'état de la permission, et la demande si nécessaire.
  ///
  /// Retourne un [LocationPermissionResult] indiquant l'état final.
  static Future<LocationPermissionResult> checkAndRequestPermission() async {
    // 1. Vérifier que le service de localisation (GPS) est activé.
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionResult.serviceDisabled;
    }

    // 2. Vérifier l'état actuel de la permission.
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // 3. Demander la permission à l'utilisateur.
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return LocationPermissionResult.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionResult.deniedForever;
    }

    // whileInUse ou always => accordée
    return LocationPermissionResult.granted;
  }

  /// Récupère la position actuelle de l'utilisateur.
  /// À appeler uniquement après avoir vérifié que la permission est accordée.
  static Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Ouvre les réglages de l'application (utile en cas de refus permanent).
  static Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  /// Ouvre les réglages de localisation du système (utile si le GPS est désactivé).
  static Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }
}
