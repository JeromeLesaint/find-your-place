// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get verifyLocation => 'Vérification de la localisation...';

  @override
  String get locationServiceDisabled =>
      'Le service de localisation (GPS) est désactivé sur votre appareil.\nVeuillez l\'activer pour continuer.';

  @override
  String get activateLocation => 'Activer la localisation';

  @override
  String get locationPermissionDeniedForever =>
      'La permission de localisation a été refusée définitivement.\nVous devez l\'activer manuellement dans les réglages de l\'application.';

  @override
  String get openSettings => 'Ouvrir les réglages';

  @override
  String get locationPermissionDenied =>
      'La permission de localisation est nécessaire pour utiliser cette application.';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get reverify => 'Revérifier';

  @override
  String get initializing => 'Initialisation...';

  @override
  String saveVehicleError(Object e) {
    return 'Erreur lors de l\'enregistrement : $e';
  }

  @override
  String get vehicleOf => 'de';

  @override
  String get editVehicle => 'Modifier le véhicule';

  @override
  String get addVehicle => 'Ajouter un véhicule';

  @override
  String get firstName => 'Prénom du propriétaire *';

  @override
  String get firstNameHint => 'Ex : Jean, Marie...';

  @override
  String get firstNameRequired => 'Le prénom est obligatoire';

  @override
  String get vehicleType => 'Type de véhicule *';

  @override
  String get vehicleName => 'Nom du véhicule *';

  @override
  String get vehicleNameHint => 'Ex : Ma voiture, Vélo de course...';

  @override
  String get vehicleNameRequired => 'Le nom est obligatoire';

  @override
  String get dimensionLength => 'Longueur (m)';

  @override
  String get dimensionWidth => 'Largeur (m)';

  @override
  String get color => 'Couleur :';

  @override
  String get notes => 'Notes';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get deleteVehicle => 'Supprimer ce véhicule ?';

  @override
  String deleteVehicleConfirmation(Object name) {
    return 'Cette action est irréversible. Voulez-vous vraiment supprimer $name ?';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String vehicleDeleted(Object name) {
    return 'Le véhicule $name a été supprimé.';
  }

  @override
  String get myVehicles => 'Mes véhicules';

  @override
  String loadingVehiclesError(Object error) {
    return 'Erreur lors du chargement : $error';
  }

  @override
  String get noVehiclesRegistered => 'Aucun véhicule enregistré';

  @override
  String get addYourFirstVehicle =>
      'Ajoutez votre première voiture, vélo ou utilitaire.';

  @override
  String get pickAColor => 'Choisissez une couleur';

  @override
  String get gotIt => 'Sélectionner';

  @override
  String get infosScreenTitle => 'Informations sur l\'application';

  @override
  String get infosScreenContent =>
      'L\'application est gratuite.\nL\'application ne gère pas le fait que les places trouvées sont libres.\nCette possibilité sera présente dans l\'application future mais payante.\nCette application a un coût.\nVous pouvez grâce au bouton ci-dessous réaliser un don pour soutenir cette application et son développement à l\'avenir. Merci';

  @override
  String get thanks => 'Merci !';

  @override
  String get thanksContent => 'Votre soutien fait vraiment la différence.';

  @override
  String get close => 'Fermer';

  @override
  String get buyingNotAvailable =>
      'Les achats ne sont pas disponibles sur cet appareil.';
}
