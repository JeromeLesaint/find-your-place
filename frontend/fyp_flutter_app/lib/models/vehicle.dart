/// Types de véhicules supportés par l'application.
enum VehicleType { voiture, suv, velo, utilitaire }

extension VehicleTypeLabel on VehicleType {
  String get label {
    switch (this) {
      case VehicleType.voiture:
        return 'Voiture';
      case VehicleType.suv:
        return 'SUV';
      case VehicleType.velo:
        return 'Vélo';
      case VehicleType.utilitaire:
        return 'Utilitaire';
      
    }
  }

  static VehicleType fromString(String value) {
    return VehicleType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => VehicleType.voiture,
    );
  }
}

/// Représente un véhicule enregistré par l'utilisateur.
class Vehicle {
  final int? id;
  final String? firstname; // Prénom du propriétaire (ex: "Jean")
  final String name; // Nom donné par l'utilisateur (ex: "Ma voiture")
  final VehicleType type;
  final double? dimensionLengthMeters; // Longueur du véhicule en mètres
  final double? dimensionWidthMeters; // Largeur du véhicule en mètres
  final String? color;
  final String? notes;

  const Vehicle({
    this.id,
    required this.firstname,
    required this.name,
    required this.type,
    this.dimensionLengthMeters,
    this.dimensionWidthMeters,
    this.color,
    this.notes,
  });

  /// Crée une copie de ce véhicule avec certains champs modifiés.
  Vehicle copyWith({
    int? id,
    String? firstname,
    String? name,
    VehicleType? type,
    double? dimensionLengthMeters,
    double? dimensionWidthMeters,
    String? color,
    String? notes,
  }) {
    return Vehicle(
      id: id ?? this.id,
      firstname: firstname ?? this.firstname,
      name: name ?? this.name,
      type: type ?? this.type,
      dimensionLengthMeters: dimensionLengthMeters ?? this.dimensionLengthMeters,
      dimensionWidthMeters: dimensionWidthMeters ?? this.dimensionWidthMeters,
      color: color ?? this.color,
      notes: notes ?? this.notes,
    );
  }

  /// Conversion vers un Map pour l'insertion/mise à jour en base SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'firstname': firstname,
      'name': name,
      'type': type.name,
      'dimension_length_meters': dimensionLengthMeters,
      'dimension_width_meters': dimensionWidthMeters,
      'color': color,
      'notes': notes,
    };
  }

  /// Construction depuis une ligne SQLite (Map).
  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as int?,
      firstname: map['firstname'] as String?,
      name: map['name'] as String,
      type: VehicleTypeLabel.fromString(map['type'] as String),
      dimensionLengthMeters: map['dimension_length_meters'] as double?,
      dimensionWidthMeters: map['dimension_width_meters'] as double?,
      color: map['color'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
