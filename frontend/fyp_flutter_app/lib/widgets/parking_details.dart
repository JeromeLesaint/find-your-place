import 'package:flutter/material.dart';
import 'package:fyp_flutter_app/l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'info_common.dart';
import '../helpers/badge_icons.dart';
import '../theme/app_colors.dart';

class ParkingDetails extends StatelessWidget {
  final Map<String, dynamic> place;
  final double maxHeight;
  final LatLng origine;
  final LatLng position;

  const ParkingDetails({super.key, required this.place, this.maxHeight = 260, required this.origine, required this.position});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final info = asMap(place['informations_generales']) ?? {};
    final capacites = asMap(place['capacites']) ?? {};
    final tarifs = asMap(place['tarifs']) ?? {};
    final tarifVehicule = asMap(place['tarif_vehicule']);
    final abonnements = asMap(place['abonnements']) ?? {};

    // --- Résumé + liens ---
    final nbPlaces = capacites['voitures'];
    final summary = <String>[
      if (nbPlaces is num) l10n.placesCount(nbPlaces.toInt()),
      if (info['exploitant'] != null) info['exploitant'].toString(),
      if (info['horaires'] != null) info['horaires'].toString(),
      if (place['hauteur_maximale_m'] is num)
        l10n.maxHeightLabel(
            formatNumber(l10n, place['hauteur_maximale_m'] as num)),
    ];
    final website = parseUrl(info['site_internet']);
    final phone = parsePhone(info['telephone']);
    final abonnes = info['utilisateurs_autorises'].toString()
        .toLowerCase()
        .contains('abonnés');

    // --- Tarifs horaires ---
    final motos = asMap(tarifs['motos']);
    final velosJournee = asMap(tarifs['velos'])?['journee'];
    final pmr = asMap(tarifs['personnes_a_mobilite_reduite'])?['tarif'];
    String parkingLabel(String k) => parkingDurationLabel(l10n, k);

    final tarifsChildren = <Widget>[
      if (hasNumbers(tarifVehicule))
        TarifGrid(
          title: l10n.vehicleYours,
          tarifs: tarifVehicule!,
          order: kParkingDurationKeys,
          labelOf: parkingLabel,
        ),
      if (hasNumbers(motos)) ...[
        const SizedBox(height: 10),
        TarifGrid(
          title: l10n.vehicleMotorcycle,
          tarifs: motos!,
          order: kParkingDurationKeys,
          labelOf: parkingLabel,
          columns: 4,
        ),
      ],
      if (velosJournee is num)
        InfoRow(l10n.bikePerDay,
            formatPrice(l10n, velosJournee, decimals: true)),
      if (pmr is String)
        InfoRow(l10n.pmrLabel,
            pmr == 'tarif_special' ? l10n.pmrSpecialRate : humanize(pmr)),
    ];

    // --- Abonnements ---
    final voitures = asMap(abonnements['voitures']);
    final groups = <(String, Map<String, dynamic>?)>[
      (l10n.subCarsResidents, asMap(voitures?['residents'])),
      (l10n.subCarsNonResidents, asMap(voitures?['non_residents'])),
      (l10n.subCarsRelayParking, asMap(voitures?['parc_relais'])),
      (l10n.subMotorcycles, asMap(abonnements['motos'])),
      (l10n.subReducedMobility,
          asMap(abonnements['personnes_a_mobilite_reduite'])),
      (l10n.subElectricVehicles, asMap(abonnements['vehicules_electriques'])),
      (l10n.subBikes, asMap(abonnements['velos'])),
      (l10n.subMotorcyclePass,
          asMap(abonnements['pass_deux_roues_motorises'])),
    ];
    final abonnementsChildren = <Widget>[];
    for (final (title, data) in groups) {
      if (data == null) continue;
      final rows = _subscriptionRows(l10n, data);
      if (rows.isEmpty) continue;
      abonnementsChildren.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Text(title,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ));
      abonnementsChildren.addAll(rows.map((r) => InfoRow(r.key, r.value)));
    }

    return InfoShell(
      maxHeight: maxHeight,
      children: [
        if (summary.isNotEmpty) Text(summary.join(' · ')),
        if (website != null || phone != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 16,
              children: [
                if (website != null)
                  LinkRow(
                    icon: Icons.open_in_new,
                    label: website.host.replaceFirst(RegExp(r'^www\.'), ''),
                    uri: website,
                    errorMessage: l10n.linkOpenWebsiteError,
                  ),
                if (phone != null)
                  LinkRow(
                    icon: Icons.phone,
                    label: phone.label,
                    uri: phone.uri,
                    errorMessage: l10n.linkCallError,
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                       const SizedBox(width: double.infinity),
                      // 6) distance à l'adresse 
                      InfoBadge(
                        label: formatDistance(distanceInMeters(origine, position)),
                        color: AppColors.neutral,
                        svgAsset: BadgeIcons.distance),
                      abonnes ? InfoBadge(
                        label: l10n.subscribersOnly,
                        color: AppColors.destructive
                        ) : InfoBadge(
                        label: l10n.public,
                        color: AppColors.markerFree
                        ),
                    ],
                  
                  ),
                   Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Text(l10n.additionalMessageParking, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold,fontStyle: FontStyle.italic)),
                    ]
                  ),
              ],
            ),
          ),
        if (tarifsChildren.isNotEmpty)
          InfoSection(
              icon: Icons.schedule,
              title: l10n.sectionHourlyRates,
              children: tarifsChildren),
        if (abonnementsChildren.isNotEmpty)
          InfoSection(
              icon: Icons.card_membership,
              title: l10n.sectionSubscriptions,
              children: abonnementsChildren),
      ],
    );
  }

  // Ordre = ordre d'affichage.
  static const List<String> _fieldOrder = [
    'disponible',
    'une_heure',
    'un_mois',
    'un_trimestre',
    'trois_mois',
    'un_an',
    'un_an_tarif_reduit',
    'un_mois_parc_relais',
    'un_an_tarif_minimum',
    'un_an_tarif_maximum',
    'parc_relais',
    'parc_relais_un_an_tarif_minimum',
    'parc_relais_un_an_tarif_maximum',
    'resident_un_mois',
    'resident_un_an',
    'velo_cargo_un_jour',
    'velo_cargo_un_mois',
    'velo_cargo_un_an',
  ];

  static String _fieldLabel(AppLocalizations l, String key) {
    switch (key) {
      case 'disponible':
        return l.fieldAvailable;
      case 'une_heure':
        return l.field1Hour;
      case 'un_mois':
        return l.field1Month;
      case 'un_trimestre':
      case 'trois_mois':
        return l.field3Months;
      case 'un_an':
        return l.field1Year;
      case 'un_an_tarif_reduit':
        return l.field1YearReduced;
      case 'un_mois_parc_relais':
        return l.field1MonthRelay;
      case 'un_an_tarif_minimum':
        return l.field1YearMin;
      case 'un_an_tarif_maximum':
        return l.field1YearMax;
      case 'parc_relais':
        return l.fieldRelayParking;
      case 'parc_relais_un_an_tarif_minimum':
        return l.fieldRelay1YearMin;
      case 'parc_relais_un_an_tarif_maximum':
        return l.fieldRelay1YearMax;
      case 'resident_un_mois':
        return l.fieldResident1Month;
      case 'resident_un_an':
        return l.fieldResident1Year;
      case 'velo_cargo_un_jour':
        return l.fieldCargoBike1Day;
      case 'velo_cargo_un_mois':
        return l.fieldCargoBike1Month;
      case 'velo_cargo_un_an':
        return l.fieldCargoBike1Year;
      default:
        return humanize(key);
    }
  }

  static List<MapEntry<String, String>> _subscriptionRows(
      AppLocalizations l10n, Map<String, dynamic> m) {
    final rows = <MapEntry<String, String>>[];
    for (final key in _fieldOrder) {
      final v = m[key];
      if (v == null) continue;
      var label = _fieldLabel(l10n, key);

      // "disponible" numérique = tarif mensuel (hypothèse), ignoré si doublon.
      if (key == 'disponible' && v is num) {
        if (m['un_mois'] != null) continue;
        label = l10n.field1Month;
      }
      rows.add(MapEntry(
          label, v is num ? formatPrice(l10n, v) : textValue(l10n, v)));
    }
    return rows;
  }
}