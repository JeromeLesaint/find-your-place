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
