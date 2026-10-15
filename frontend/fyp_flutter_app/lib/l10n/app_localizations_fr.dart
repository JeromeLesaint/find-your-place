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

  @override
  String get noProvidedAddress => 'Adresse non renseignée';

  @override
  String districtOfParis(Object arrond) {
    return 'Paris ${arrond}e';
  }

  @override
  String get linkOpenWebsiteError => 'Impossible d’ouvrir le site.';

  @override
  String get linkCallError => 'Impossible de lancer l’appel.';

  @override
  String placesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String maxHeightLabel(String value) {
    return 'Hauteur max $value m';
  }

  @override
  String durationMinutes(int n) {
    return '$n min';
  }

  @override
  String durationHours(int n) {
    return '$n h';
  }

  @override
  String durationHoursMinutes(int h, int m) {
    return '$h h $m';
  }

  @override
  String unitSquareMeters(String value) {
    return '$value m²';
  }

  @override
  String timeRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String vehicleDayTitle(String vehicle, String day) {
    return '$vehicle · $day';
  }

  @override
  String get valueYes => 'Oui';

  @override
  String get valueNo => 'Non';

  @override
  String get pmrSpecialRate => 'Tarif spécial';

  @override
  String get parkingDefaultTitle => 'Parking';

  @override
  String get goThere => 'Y aller';

  @override
  String get sectionHourlyRates => 'Tarifs horaires';

  @override
  String get sectionSubscriptions => 'Abonnements';

  @override
  String get sectionOtherVehicles => 'Autres véhicules';

  @override
  String get sectionLocation => 'Emplacement';

  @override
  String get sectionRegulation => 'Réglementation';

  @override
  String get vehicleYours => 'Votre véhicule';

  @override
  String get vehicleCar => 'Voiture';

  @override
  String get vehicleMotorcycle => 'Deux-roues motorisés';

  @override
  String get vehicleSuv => 'SUV';

  @override
  String get bikePerDay => 'Vélo · journée';

  @override
  String get pmrLabel => 'PMR';

  @override
  String get subCarsResidents => 'Voitures · Résidents';

  @override
  String get subCarsNonResidents => 'Voitures · Non-résidents';

  @override
  String get subCarsRelayParking => 'Voitures · Parc-relais';

  @override
  String get subMotorcycles => 'Motos';

  @override
  String get subReducedMobility => 'Personnes à mobilité réduite';

  @override
  String get subElectricVehicles => 'Véhicules électriques';

  @override
  String get subBikes => 'Vélos';

  @override
  String get subMotorcyclePass => 'Pass deux-roues motorisés';

  @override
  String get fieldAvailable => 'Disponible';

  @override
  String get field1Hour => '1 heure';

  @override
  String get field1Month => '1 mois';

  @override
  String get field3Months => '3 mois';

  @override
  String get field1Year => '1 an';

  @override
  String get field1YearReduced => '1 an (tarif réduit)';

  @override
  String get field1MonthRelay => '1 mois (parc-relais)';

  @override
  String get field1YearMin => '1 an (min)';

  @override
  String get field1YearMax => '1 an (max)';

  @override
  String get fieldRelayParking => 'Parc-relais';

  @override
  String get fieldRelay1YearMin => 'Parc-relais 1 an (min)';

  @override
  String get fieldRelay1YearMax => 'Parc-relais 1 an (max)';

  @override
  String get fieldResident1Month => 'Résident · 1 mois';

  @override
  String get fieldResident1Year => 'Résident · 1 an';

  @override
  String get fieldCargoBike1Day => 'Vélo cargo · 1 jour';

  @override
  String get fieldCargoBike1Month => 'Vélo cargo · 1 mois';

  @override
  String get fieldCargoBike1Year => 'Vélo cargo · 1 an';

  @override
  String get regimeDelivery => 'Livraison';

  @override
  String get regimePaidMixed => 'Payant — résident possible';

  @override
  String get regimePaidRotating => 'Payant — visiteurs';

  @override
  String get regimeElectric => 'Électrique';

  @override
  String get badgeNoParking => 'Stationnement interdit';

  @override
  String get dayMonFri => 'Lundi – vendredi';

  @override
  String get daySat => 'Samedi';

  @override
  String get dayMonSat => 'Lundi – samedi';

  @override
  String get rowType => 'Type';

  @override
  String get rowPosition => 'Position';

  @override
  String get rowSide => 'Côté';

  @override
  String get rowPlaces => 'Places';

  @override
  String get rowSurveyedPlaces => 'Places relevées';

  @override
  String get rowSurfacePerPlace => 'Surface par place';

  @override
  String get rowResidentZone => 'Zone résident';

  @override
  String get rowTariffZone => 'Zone tarifaire';

  @override
  String get rowSector => 'Secteur';

  @override
  String get rowChargingPoint => 'Borne de recharge';

  @override
  String get rowBikeSharing => 'Vélos en libre-service';

  @override
  String get rowRegime => 'Régime';

  @override
  String get rowTimeSlots => 'Plages horaires';

  @override
  String get rowHorizontalSign => 'Signalisation horizontale';

  @override
  String get rowVerticalSign => 'Signalisation verticale';

  @override
  String get rowCompliance => 'Conformité';

  @override
  String get badgeBike => 'Vélo';

  @override
  String get badgeMotorcycle => 'Moto';

  @override
  String get badgeCoach => 'Autocar';

  @override
  String get badgeSpecialRegime => 'Régime spécial';

  @override
  String get regimePaid => 'Payant';

  @override
  String get regimeFree => 'Gratuit';

  @override
  String get parkingTypeLongitudinal => 'Longitudinal';

  @override
  String get parkingTypeBataille => 'Bataille';

  @override
  String get parkingTypeEpi => 'Épi';

  @override
  String get sideEven => 'Côté pair';

  @override
  String get sideOdd => 'Côté impair';

  @override
  String get additionalMessageStreet =>
      'Nombre total de places, pas de disponibilité en temps réel.';

  @override
  String get additionalMessageParking =>
      'Les capacités indiquent le nombre total de places, pas les places libres en temps réel.';

  @override
  String get subscribersOnly => 'Abonnés';

  @override
  String get public => 'Ouvert au public';
}
