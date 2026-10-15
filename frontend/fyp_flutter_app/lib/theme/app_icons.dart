import 'package:flutter/material.dart';
import '../models/vehicle.dart';

/// Classe utilitaire pour les icônes utilisées dans l'application.
/// Elle centralise les icônes afin de faciliter leur modification et leur réutilisation.
/// Par exemple, si l'on souhaite changer l'icône de localisation, il suffit de modifier la valeur ici.
class AppIcons {
  AppIcons._();

  
  static const IconData settings = Icons.settings; // Icône pour représenter les paramètres ou les réglages de l'application.
  static const IconData question = Icons.question_mark; // Icône pour représenter une question ou une aide contextuelle.
  static const IconData save = Icons.save_outlined; // Icône pour représenter l'action de sauvegarde ou d'enregistrement.
  static const IconData edit = Icons.edit_outlined; // Icône pour représenter l'action d'édition ou de modification.
  static const IconData delete = Icons.delete_outline; // Icône pour représenter l'action de suppression ou de retrait.
  static const IconData refresh = Icons.refresh; // Icône pour indiquer une action de rafraîchissement ou de mise à jour.
  static const IconData locationOff = Icons.location_off; // Icône pour indiquer que la localisation est désactivée ou refusée.
  static const IconData directionsCarFilledOutlined = Icons.directions_car_filled_outlined; // Icône pour représenter un véhicule de type voiture (rempli).
  static const IconData add=Icons.add; // Icône pour représenter l'action d'ajout ou de création d'un nouvel élément.
  static const IconData palette = Icons.palette; // Icône pour représenter le sélecteur de couleur.
  static const IconData info = Icons.info; // Icône pour représenter la page d'informations.
  static const IconData place = Icons.place; // Icône pour représenter un lieu ou une position sur la carte.

  static IconData iconForType(VehicleType type) {
    switch (type) {
      case VehicleType.voiture:
        return Icons.directions_car; // Icône pour représenter un véhicule de type voiture.
      case VehicleType.suv:
        return Icons.directions_car_filled; // Icône pour représenter un véhicule de type SUV.
      case VehicleType.velo:
        return Icons.pedal_bike; // Icône pour représenter un véhicule de type vélo.
      case VehicleType.utilitaire:
        return Icons.local_shipping;
    }
  }
}