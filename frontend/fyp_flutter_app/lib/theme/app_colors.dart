import 'package:flutter/material.dart';
import '../models/vehicle.dart';

/// Palette de couleurs reprise directement du logo "Find Your Place" :
/// orange/jaune pour l'énergie et le dynamisme, rust foncé pour les accents
/// (moyeu de roue du logo), crème pour les fonds clairs.
class AppColors {
  AppColors._();

  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color accentYellow = Color(0xFFFFC145);
  static const Color darkRust = Color(0xFF7C2D12);
  static const Color cream = Color(0xFFFFF8F0);
  static const Color textDark = Color(0xFF3D2314);
  static const Color settingsColor = Color.fromARGB(255, 200, 27, 177); // Couleur de texte claire pour les fonds sombres.


  /// Dégradé principal utilisé sur les boutons/actions primaires,
  /// identique à l'esprit du logo (orange -> jaune).
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryOrange, accentYellow],
  );

  /// Couleur utilisée pour les actions destructrices (supprimer).
  static const Color destructive = Color(0xFFB3261E);

  static Color colorForType(VehicleType type) {
    switch (type) {
      case VehicleType.voiture:
        return Colors.blue; // Couleur pour représenter un véhicule de type voiture.
      case VehicleType.suv:
        return Colors.green; // Couleur pour représenter un véhicule de type SUV.
      case VehicleType.velo:
        return Colors.yellow; // Couleur pour représenter un véhicule de type vélo.
      case VehicleType.utilitaire:
        return Colors.teal; // Couleur pour représenter un véhicule de type utilitaire.
    }
  }

  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
