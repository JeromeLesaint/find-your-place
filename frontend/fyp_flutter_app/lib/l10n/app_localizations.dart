import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// No description provided for @verifyLocation.
  ///
  /// In fr, this message translates to:
  /// **'Vérification de la localisation...'**
  String get verifyLocation;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Le service de localisation (GPS) est désactivé sur votre appareil.\nVeuillez l\'activer pour continuer.'**
  String get locationServiceDisabled;

  /// No description provided for @activateLocation.
  ///
  /// In fr, this message translates to:
  /// **'Activer la localisation'**
  String get activateLocation;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In fr, this message translates to:
  /// **'La permission de localisation a été refusée définitivement.\nVous devez l\'activer manuellement dans les réglages de l\'application.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @openSettings.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les réglages'**
  String get openSettings;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'La permission de localisation est nécessaire pour utiliser cette application.'**
  String get locationPermissionDenied;

  /// No description provided for @tryAgain.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get tryAgain;

  /// No description provided for @reverify.
  ///
  /// In fr, this message translates to:
  /// **'Revérifier'**
  String get reverify;

  /// No description provided for @initializing.
  ///
  /// In fr, this message translates to:
  /// **'Initialisation...'**
  String get initializing;

  /// No description provided for @saveVehicleError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'enregistrement : {e}'**
  String saveVehicleError(Object e);

  /// No description provided for @vehicleOf.
  ///
  /// In fr, this message translates to:
  /// **'de'**
  String get vehicleOf;

  /// No description provided for @editVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le véhicule'**
  String get editVehicle;

  /// No description provided for @addVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un véhicule'**
  String get addVehicle;

  /// No description provided for @firstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom du propriétaire *'**
  String get firstName;

  /// No description provided for @firstNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Jean, Marie...'**
  String get firstNameHint;

  /// No description provided for @firstNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le prénom est obligatoire'**
  String get firstNameRequired;

  /// No description provided for @vehicleType.
  ///
  /// In fr, this message translates to:
  /// **'Type de véhicule *'**
  String get vehicleType;

  /// No description provided for @vehicleName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du véhicule *'**
  String get vehicleName;

  /// No description provided for @vehicleNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Ma voiture, Vélo de course...'**
  String get vehicleNameHint;

  /// No description provided for @vehicleNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est obligatoire'**
  String get vehicleNameRequired;

  /// No description provided for @dimensionLength.
  ///
  /// In fr, this message translates to:
  /// **'Longueur (m)'**
  String get dimensionLength;

  /// No description provided for @dimensionWidth.
  ///
  /// In fr, this message translates to:
  /// **'Largeur (m)'**
  String get dimensionWidth;

  /// No description provided for @color.
  ///
  /// In fr, this message translates to:
  /// **'Couleur :'**
  String get color;

  /// No description provided for @notes.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @saveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get saveChanges;

  /// No description provided for @deleteVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce véhicule ?'**
  String get deleteVehicle;

  /// No description provided for @deleteVehicleConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible. Voulez-vous vraiment supprimer {name} ?'**
  String deleteVehicleConfirmation(Object name);

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @vehicleDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Le véhicule {name} a été supprimé.'**
  String vehicleDeleted(Object name);

  /// No description provided for @myVehicles.
  ///
  /// In fr, this message translates to:
  /// **'Mes véhicules'**
  String get myVehicles;

  /// No description provided for @loadingVehiclesError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement : {error}'**
  String loadingVehiclesError(Object error);

  /// No description provided for @noVehiclesRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Aucun véhicule enregistré'**
  String get noVehiclesRegistered;

  /// No description provided for @addYourFirstVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre première voiture, vélo ou utilitaire.'**
  String get addYourFirstVehicle;

  /// No description provided for @pickAColor.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une couleur'**
  String get pickAColor;

  /// No description provided for @gotIt.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner'**
  String get gotIt;

  /// No description provided for @infosScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Informations sur l\'application'**
  String get infosScreenTitle;

  /// No description provided for @infosScreenContent.
  ///
  /// In fr, this message translates to:
  /// **'L\'application est gratuite.\nL\'application ne gère pas le fait que les places trouvées sont libres.\nCette possibilité sera présente dans l\'application future mais payante.\nCette application a un coût.\nVous pouvez grâce au bouton ci-dessous réaliser un don pour soutenir cette application et son développement à l\'avenir. Merci'**
  String get infosScreenContent;

  /// No description provided for @thanks.
  ///
  /// In fr, this message translates to:
  /// **'Merci !'**
  String get thanks;

  /// No description provided for @thanksContent.
  ///
  /// In fr, this message translates to:
  /// **'Votre soutien fait vraiment la différence.'**
  String get thanksContent;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @buyingNotAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Les achats ne sont pas disponibles sur cet appareil.'**
  String get buyingNotAvailable;

  /// No description provided for @noProvidedAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse non renseignée'**
  String get noProvidedAddress;

  /// No description provided for @districtOfParis.
  ///
  /// In fr, this message translates to:
  /// **'Paris {arrond}e'**
  String districtOfParis(Object arrond);

  /// No description provided for @linkOpenWebsiteError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’ouvrir le site.'**
  String get linkOpenWebsiteError;

  /// No description provided for @linkCallError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lancer l’appel.'**
  String get linkCallError;

  /// No description provided for @placesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 place} other{{count} places}}'**
  String placesCount(int count);

  /// No description provided for @maxHeightLabel.
  ///
  /// In fr, this message translates to:
  /// **'Hauteur max {value} m'**
  String maxHeightLabel(String value);

  /// No description provided for @durationMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{n} min'**
  String durationMinutes(int n);

  /// No description provided for @durationHours.
  ///
  /// In fr, this message translates to:
  /// **'{n} h'**
  String durationHours(int n);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{h} h {m}'**
  String durationHoursMinutes(int h, int m);

  /// No description provided for @unitSquareMeters.
  ///
  /// In fr, this message translates to:
  /// **'{value} m²'**
  String unitSquareMeters(String value);

  /// No description provided for @timeRange.
  ///
  /// In fr, this message translates to:
  /// **'{start} – {end}'**
  String timeRange(String start, String end);

  /// No description provided for @vehicleDayTitle.
  ///
  /// In fr, this message translates to:
  /// **'{vehicle} · {day}'**
  String vehicleDayTitle(String vehicle, String day);

  /// No description provided for @valueYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get valueYes;

  /// No description provided for @valueNo.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get valueNo;

  /// No description provided for @pmrSpecialRate.
  ///
  /// In fr, this message translates to:
  /// **'Tarif spécial'**
  String get pmrSpecialRate;

  /// No description provided for @parkingDefaultTitle.
  ///
  /// In fr, this message translates to:
  /// **'Parking'**
  String get parkingDefaultTitle;

  /// No description provided for @goThere.
  ///
  /// In fr, this message translates to:
  /// **'Y aller'**
  String get goThere;

  /// No description provided for @sectionHourlyRates.
  ///
  /// In fr, this message translates to:
  /// **'Tarifs horaires'**
  String get sectionHourlyRates;

  /// No description provided for @sectionSubscriptions.
  ///
  /// In fr, this message translates to:
  /// **'Abonnements'**
  String get sectionSubscriptions;

  /// No description provided for @sectionOtherVehicles.
  ///
  /// In fr, this message translates to:
  /// **'Autres véhicules'**
  String get sectionOtherVehicles;

  /// No description provided for @sectionLocation.
  ///
  /// In fr, this message translates to:
  /// **'Emplacement'**
  String get sectionLocation;

  /// No description provided for @sectionRegulation.
  ///
  /// In fr, this message translates to:
  /// **'Réglementation'**
  String get sectionRegulation;

  /// No description provided for @vehicleYours.
  ///
  /// In fr, this message translates to:
  /// **'Votre véhicule'**
  String get vehicleYours;

  /// No description provided for @vehicleCar.
  ///
  /// In fr, this message translates to:
  /// **'Voiture'**
  String get vehicleCar;

  /// No description provided for @vehicleMotorcycle.
  ///
  /// In fr, this message translates to:
  /// **'Deux-roues motorisés'**
  String get vehicleMotorcycle;

  /// No description provided for @vehicleSuv.
  ///
  /// In fr, this message translates to:
  /// **'SUV'**
  String get vehicleSuv;

  /// No description provided for @bikePerDay.
  ///
  /// In fr, this message translates to:
  /// **'Vélo · journée'**
  String get bikePerDay;

  /// No description provided for @pmrLabel.
  ///
  /// In fr, this message translates to:
  /// **'PMR'**
  String get pmrLabel;

  /// No description provided for @subCarsResidents.
  ///
  /// In fr, this message translates to:
  /// **'Voitures · Résidents'**
  String get subCarsResidents;

  /// No description provided for @subCarsNonResidents.
  ///
  /// In fr, this message translates to:
  /// **'Voitures · Non-résidents'**
  String get subCarsNonResidents;

  /// No description provided for @subCarsRelayParking.
  ///
  /// In fr, this message translates to:
  /// **'Voitures · Parc-relais'**
  String get subCarsRelayParking;

  /// No description provided for @subMotorcycles.
  ///
  /// In fr, this message translates to:
  /// **'Motos'**
  String get subMotorcycles;

  /// No description provided for @subReducedMobility.
  ///
  /// In fr, this message translates to:
  /// **'Personnes à mobilité réduite'**
  String get subReducedMobility;

  /// No description provided for @subElectricVehicles.
  ///
  /// In fr, this message translates to:
  /// **'Véhicules électriques'**
  String get subElectricVehicles;

  /// No description provided for @subBikes.
  ///
  /// In fr, this message translates to:
  /// **'Vélos'**
  String get subBikes;

  /// No description provided for @subMotorcyclePass.
  ///
  /// In fr, this message translates to:
  /// **'Pass deux-roues motorisés'**
  String get subMotorcyclePass;

  /// No description provided for @fieldAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get fieldAvailable;

  /// No description provided for @field1Hour.
  ///
  /// In fr, this message translates to:
  /// **'1 heure'**
  String get field1Hour;

  /// No description provided for @field1Month.
  ///
  /// In fr, this message translates to:
  /// **'1 mois'**
  String get field1Month;

  /// No description provided for @field3Months.
  ///
  /// In fr, this message translates to:
  /// **'3 mois'**
  String get field3Months;

  /// No description provided for @field1Year.
  ///
  /// In fr, this message translates to:
  /// **'1 an'**
  String get field1Year;

  /// No description provided for @field1YearReduced.
  ///
  /// In fr, this message translates to:
  /// **'1 an (tarif réduit)'**
  String get field1YearReduced;

  /// No description provided for @field1MonthRelay.
  ///
  /// In fr, this message translates to:
  /// **'1 mois (parc-relais)'**
  String get field1MonthRelay;

  /// No description provided for @field1YearMin.
  ///
  /// In fr, this message translates to:
  /// **'1 an (min)'**
  String get field1YearMin;

  /// No description provided for @field1YearMax.
  ///
  /// In fr, this message translates to:
  /// **'1 an (max)'**
  String get field1YearMax;

  /// No description provided for @fieldRelayParking.
  ///
  /// In fr, this message translates to:
  /// **'Parc-relais'**
  String get fieldRelayParking;

  /// No description provided for @fieldRelay1YearMin.
  ///
  /// In fr, this message translates to:
  /// **'Parc-relais 1 an (min)'**
  String get fieldRelay1YearMin;

  /// No description provided for @fieldRelay1YearMax.
  ///
  /// In fr, this message translates to:
  /// **'Parc-relais 1 an (max)'**
  String get fieldRelay1YearMax;

  /// No description provided for @fieldResident1Month.
  ///
  /// In fr, this message translates to:
  /// **'Résident · 1 mois'**
  String get fieldResident1Month;

  /// No description provided for @fieldResident1Year.
  ///
  /// In fr, this message translates to:
  /// **'Résident · 1 an'**
  String get fieldResident1Year;

  /// No description provided for @fieldCargoBike1Day.
  ///
  /// In fr, this message translates to:
  /// **'Vélo cargo · 1 jour'**
  String get fieldCargoBike1Day;

  /// No description provided for @fieldCargoBike1Month.
  ///
  /// In fr, this message translates to:
  /// **'Vélo cargo · 1 mois'**
  String get fieldCargoBike1Month;

  /// No description provided for @fieldCargoBike1Year.
  ///
  /// In fr, this message translates to:
  /// **'Vélo cargo · 1 an'**
  String get fieldCargoBike1Year;

  /// No description provided for @regimeDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get regimeDelivery;

  /// No description provided for @regimePaidMixed.
  ///
  /// In fr, this message translates to:
  /// **'Payant — résident possible'**
  String get regimePaidMixed;

  /// No description provided for @regimePaidRotating.
  ///
  /// In fr, this message translates to:
  /// **'Payant — visiteurs'**
  String get regimePaidRotating;

  /// No description provided for @regimeElectric.
  ///
  /// In fr, this message translates to:
  /// **'Électrique'**
  String get regimeElectric;

  /// No description provided for @badgeNoParking.
  ///
  /// In fr, this message translates to:
  /// **'Stationnement interdit'**
  String get badgeNoParking;

  /// No description provided for @dayMonFri.
  ///
  /// In fr, this message translates to:
  /// **'Lundi – vendredi'**
  String get dayMonFri;

  /// No description provided for @daySat.
  ///
  /// In fr, this message translates to:
  /// **'Samedi'**
  String get daySat;

  /// No description provided for @dayMonSat.
  ///
  /// In fr, this message translates to:
  /// **'Lundi – samedi'**
  String get dayMonSat;

  /// No description provided for @rowType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get rowType;

  /// No description provided for @rowPosition.
  ///
  /// In fr, this message translates to:
  /// **'Position'**
  String get rowPosition;

  /// No description provided for @rowSide.
  ///
  /// In fr, this message translates to:
  /// **'Côté'**
  String get rowSide;

  /// No description provided for @rowPlaces.
  ///
  /// In fr, this message translates to:
  /// **'Places'**
  String get rowPlaces;

  /// No description provided for @rowSurveyedPlaces.
  ///
  /// In fr, this message translates to:
  /// **'Places relevées'**
  String get rowSurveyedPlaces;

  /// No description provided for @rowSurfacePerPlace.
  ///
  /// In fr, this message translates to:
  /// **'Surface par place'**
  String get rowSurfacePerPlace;

  /// No description provided for @rowResidentZone.
  ///
  /// In fr, this message translates to:
  /// **'Zone résident'**
  String get rowResidentZone;

  /// No description provided for @rowTariffZone.
  ///
  /// In fr, this message translates to:
  /// **'Zone tarifaire'**
  String get rowTariffZone;

  /// No description provided for @rowSector.
  ///
  /// In fr, this message translates to:
  /// **'Secteur'**
  String get rowSector;

  /// No description provided for @rowChargingPoint.
  ///
  /// In fr, this message translates to:
  /// **'Borne de recharge'**
  String get rowChargingPoint;

  /// No description provided for @rowBikeSharing.
  ///
  /// In fr, this message translates to:
  /// **'Vélos en libre-service'**
  String get rowBikeSharing;

  /// No description provided for @rowRegime.
  ///
  /// In fr, this message translates to:
  /// **'Régime'**
  String get rowRegime;

  /// No description provided for @rowTimeSlots.
  ///
  /// In fr, this message translates to:
  /// **'Plages horaires'**
  String get rowTimeSlots;

  /// No description provided for @rowHorizontalSign.
  ///
  /// In fr, this message translates to:
  /// **'Signalisation horizontale'**
  String get rowHorizontalSign;

  /// No description provided for @rowVerticalSign.
  ///
  /// In fr, this message translates to:
  /// **'Signalisation verticale'**
  String get rowVerticalSign;

  /// No description provided for @rowCompliance.
  ///
  /// In fr, this message translates to:
  /// **'Conformité'**
  String get rowCompliance;

  /// No description provided for @badgeBike.
  ///
  /// In fr, this message translates to:
  /// **'Vélo'**
  String get badgeBike;

  /// No description provided for @badgeMotorcycle.
  ///
  /// In fr, this message translates to:
  /// **'Moto'**
  String get badgeMotorcycle;

  /// No description provided for @badgeCoach.
  ///
  /// In fr, this message translates to:
  /// **'Autocar'**
  String get badgeCoach;

  /// No description provided for @badgeSpecialRegime.
  ///
  /// In fr, this message translates to:
  /// **'Régime spécial'**
  String get badgeSpecialRegime;

  /// No description provided for @regimePaid.
  ///
  /// In fr, this message translates to:
  /// **'Payant'**
  String get regimePaid;

  /// No description provided for @regimeFree.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get regimeFree;

  /// No description provided for @parkingTypeLongitudinal.
  ///
  /// In fr, this message translates to:
  /// **'Longitudinal'**
  String get parkingTypeLongitudinal;

  /// No description provided for @parkingTypeBataille.
  ///
  /// In fr, this message translates to:
  /// **'Bataille'**
  String get parkingTypeBataille;

  /// No description provided for @parkingTypeEpi.
  ///
  /// In fr, this message translates to:
  /// **'Épi'**
  String get parkingTypeEpi;

  /// No description provided for @sideEven.
  ///
  /// In fr, this message translates to:
  /// **'Côté pair'**
  String get sideEven;

  /// No description provided for @sideOdd.
  ///
  /// In fr, this message translates to:
  /// **'Côté impair'**
  String get sideOdd;

  /// No description provided for @additionalMessageStreet.
  ///
  /// In fr, this message translates to:
  /// **'Nombre total de places, pas de disponibilité en temps réel.'**
  String get additionalMessageStreet;

  /// No description provided for @additionalMessageParking.
  ///
  /// In fr, this message translates to:
  /// **'Les capacités indiquent le nombre total de places, pas les places libres en temps réel.'**
  String get additionalMessageParking;

  /// No description provided for @subscribersOnly.
  ///
  /// In fr, this message translates to:
  /// **'Abonnés'**
  String get subscribersOnly;

  /// No description provided for @public.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert au public'**
  String get public;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
