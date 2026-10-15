import 'package:flutter/material.dart';
import 'package:fyp_flutter_app/l10n/app_localizations.dart';
import 'info_common.dart';
import '../helpers/badge_icons.dart';
import '../helpers/marker_icons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_colors.dart';

class StreetDetails extends StatelessWidget {
  final Map<String, dynamic> place;
  final double maxHeight;
  final LatLng origine;
  final LatLng position;

  const StreetDetails({super.key, required this.place, this.maxHeight = 330, required this.origine, required this.position});

    
  List<Widget> _badges(AppLocalizations l10n) {
    final category = markerCategoryFor(place);
    final color = markerStyleFor(category).color; // même couleur que le marqueur
    final regpri = (place['regpri'] ?? '').toString();

    final badges = <Widget>[
      // 1) Usage : voiture, électrique, vélo, moto, PMR, livraison, autocar…
      InfoBadge(
        label: _usageLabel(l10n, category),
        color: color,
        svgAsset: BadgeIcons.usage(category),
      ),
    ];

    // 2) Tarification (uniquement payant / gratuit)
    if (category == MarkerCategory.payant || category == MarkerCategory.gratuit) {
      final free = category == MarkerCategory.gratuit;
      badges.add(InfoBadge(
        label: free ? l10n.regimeFree : _paidLabel(l10n, regpri),
        color: color,
        svgAsset: free ? BadgeIcons.free : BadgeIcons.paid,
      ));
    }

    // 3) Type de stationnement : longitudinal / bataille / épi
    final type = _parkingType(l10n, place['typsta']);
    if (type != null) {
      badges.add(InfoBadge(
          label: type.label, color: AppColors.neutral, svgAsset: type.svg));
    }

    // 4) Nombre de places
    final nb = place['placal'] ?? place['plarel'];
    if (nb is num) {
      badges.add(InfoBadge(
          label: l10n.placesCount(nb.toInt()),
          color: AppColors.neutral,
          svgAsset: BadgeIcons.places));
    }

    // 5) Côté pair / impair
    final parite = place['parite']?.toString().toLowerCase();
    if (parite == 'pair' || parite == 'impair') {
      badges.add(InfoBadge(
          label: parite == 'pair' ? l10n.sideEven : l10n.sideOdd,
          color: AppColors.neutral,
          svgAsset: BadgeIcons.parity));
    }

    // 6) distance à l'adresse 
    badges.add(InfoBadge(
          label: formatDistance(distanceInMeters(origine, position)),
          color: AppColors.neutral,
          svgAsset: BadgeIcons.distance));
    // 7) Stationnement interdit
    /*if (place['interdit'] == true) {
      badges.add(InfoBadge(
          label: l10n.badgeNoParking, color: Colors.red, icon: Icons.block));
    }*/
    return badges;
  }

  static String _usageLabel(AppLocalizations l, MarkerCategory c) => switch (c) {
        MarkerCategory.electrique => l.regimeElectric,
        MarkerCategory.velo => l.badgeBike,
        MarkerCategory.moto => l.badgeMotorcycle,
        MarkerCategory.pmr => l.pmrLabel,
        MarkerCategory.livraison => l.regimeDelivery,
        MarkerCategory.autocar => l.badgeCoach,
        MarkerCategory.gratuit ||
        MarkerCategory.payant ||
        MarkerCategory.parking =>
          l.vehicleCar,
        MarkerCategory.reserve => l.badgeSpecialRegime,
      };

  static String _paidLabel(AppLocalizations l, String regpri) {
    if (regpri == 'PAYANT MIXTE') return l.regimePaidMixed;
    if (regpri == 'PAYANT ROTATIF') return l.regimePaidRotating;
    return l.regimePaid;
  }

  static ({String svg, String label})? _parkingType(
      AppLocalizations l, dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().toLowerCase().replaceAll('é', 'e');
    if (s.startsWith('long')) {
      return (svg: BadgeIcons.parkingLongitudinal, label: l.parkingTypeLongitudinal);
    }
    if (s.startsWith('batai')) {
      return (svg: BadgeIcons.parkingBataille, label: l.parkingTypeBataille);
    }
    if (s.startsWith('epi')) {
      return (svg: BadgeIcons.parkingEpi, label: l.parkingTypeEpi);
    }
    return null; // valeur inconnue : pas de badge (la ligne « Type » reste affichée)
  }


  static String _dayLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'lundi_vendredi':
        return l10n.dayMonFri;
      case 'samedi':
        return l10n.daySat;
      case 'lundi_samedi':
        return l10n.dayMonSat;
      default:
        return humanize(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final badges = _badges(l10n);
     

    // --- Tarifs (véhicule de la requête) ---
    final tarifsChildren = _dayGrids(l10n, asMap(place['tarif_vehicule']));

    // --- Tarifs des autres véhicules ---
    final tarifsByVehicle = asMap(place['tarifs']);
    final vehicles = <(String, String)>[
      ('voiture', l10n.vehicleCar),
      ('deux_roues_motorises', l10n.vehicleMotorcycle),
      ('suv', l10n.vehicleSuv),
    ];
    final autres = <Widget>[];
    for (final (key, label) in vehicles) {
      final grids =
          _dayGrids(l10n, asMap(tarifsByVehicle?[key]), prefix: label);
      if (grids.isEmpty) continue;
      if (autres.isNotEmpty) autres.add(const SizedBox(height: 12));
      autres.addAll(grids);
    }

    // --- Emplacement ---
    final placal = place['placal'];
    final plarel = place['plarel'];
    final surface = place['surface_par_place'];
    final emplacement = _rows([
      (l10n.rowType, _s(l10n, place['typsta'])),
      (l10n.rowPosition, _s(l10n, place['locsta'])),
      (l10n.rowSide, _s(l10n, place['parite'])),
      (l10n.rowPlaces, placal is num ? '${placal.toInt()}' : null),
      (l10n.rowSurveyedPlaces,
          plarel is num && plarel != placal ? '${plarel.toInt()}' : null),
      (l10n.rowSurfacePerPlace,
          surface is num ? l10n.unitSquareMeters(formatNumber(l10n, surface)) : null),
      (l10n.rowResidentZone, _s(l10n, place['zoneres'])),
      (l10n.rowTariffZone, _s(l10n, place['zone_tarifaire'])),
      (l10n.rowSector, _s(l10n, place['stv'])),
      (l10n.rowChargingPoint, _s(l10n, place['typemob'])),
      (l10n.rowBikeSharing,
          _s(l10n, place['stationnement_autorises_aux_velos_en_libre_service'])),
    ]);

    // --- Réglementation ---
    final reglementation = _rows([
      (l10n.rowRegime, _s(l10n, place['regpar'])),
      (l10n.rowTimeSlots, _plages(l10n)),
      (l10n.rowHorizontalSign, _s(l10n, place['signhor'])),
      (l10n.rowVerticalSign, _s(l10n, place['signvert'])),
      (l10n.rowCompliance, _s(l10n, place['confsign'])),
    ]);

    return InfoShell(
      maxHeight: maxHeight,
      children: [
        if (badges.isNotEmpty)
            Wrap(spacing: 6, runSpacing: 6, children: badges),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            Text(l10n.additionalMessageStreet, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold,fontStyle: FontStyle.italic)),
          ]
        ),
        if (tarifsChildren.isNotEmpty)
          InfoSection(
              icon: Icons.schedule,
              title: l10n.sectionHourlyRates,
              children: tarifsChildren),
        if (autres.isNotEmpty)
          InfoSection(
              icon: Icons.two_wheeler,
              title: l10n.sectionOtherVehicles,
              children: autres),
        if (emplacement.isNotEmpty)
          InfoSection(
              icon: Icons.place_outlined,
              title: l10n.sectionLocation,
              children: emplacement),
        if (reglementation.isNotEmpty)
          InfoSection(
              icon: Icons.traffic,
              title: l10n.sectionRegulation,
              children: reglementation),
      ],
    );
  }

  // ---------------------------------------------------------------- helpers

  static String? _s(AppLocalizations l10n, dynamic v) =>
      v == null ? null : textValue(l10n, v);

  static List<Widget> _rows(List<(String, String?)> data) => [
        for (final (label, value) in data)
          if (value != null && value.isNotEmpty) InfoRow(label, value),
      ];

  String? _plages(AppLocalizations l10n) {
    final parts = <String>[];
    for (var i = 1; i <= 3; i++) {
      final d = place['plage_hor${i}_debut'];
      final f = place['plage_hor${i}_fin'];
      if (d != null && f != null) parts.add(l10n.timeRange('$d', '$f'));
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static bool _sameTarif(Map<String, dynamic> a, Map<String, dynamic> b) =>
      kStreetDurationKeys.every((k) => a[k] == b[k]);

  static List<Widget> _dayGrids(AppLocalizations l10n,
      Map<String, dynamic>? byDay,
      {String? prefix}) {
    if (byDay == null) return const [];

    final entries = <MapEntry<String, Map<String, dynamic>>>[
      for (final e in byDay.entries)
        if (hasNumbers(asMap(e.value))) MapEntry(e.key, asMap(e.value)!),
    ];
    if (entries.isEmpty) return const [];

    final lv = asMap(byDay['lundi_vendredi']);
    final sa = asMap(byDay['samedi']);
    if (lv != null && sa != null && _sameTarif(lv, sa)) {
      entries
        ..removeWhere((e) => e.key == 'lundi_vendredi' || e.key == 'samedi')
        ..insert(0, MapEntry('lundi_samedi', lv));
    }

    final widgets = <Widget>[];
    for (final e in entries) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 10));
      final day = _dayLabel(l10n, e.key);
      widgets.add(TarifGrid(
        title: prefix == null ? day : l10n.vehicleDayTitle(prefix, day),
        tarifs: e.value,
        order: kStreetDurationKeys,
        labelOf: (k) => streetDurationLabel(l10n, k),
      ));
    }
    return widgets;
  }
}