import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_colors.dart';

enum MarkerCategory {
  parking,
  electrique,
  velo,
  moto,
  pmr,
  livraison,
  autocar,
  gratuit,
  payant,
  reserve,
}


MarkerCategory markerCategoryFor(Map<String, dynamic> e) {
  if (e['type_resultat'] == 'parking' || e['type_donnee'] == 'parking') {
    return MarkerCategory.parking;
  }

  final regpri = (e['regpri'] ?? '').toString();
  final regpar = (e['regpar'] ?? '').toString();
  final special = regpar.toLowerCase();

  if (regpri == 'ELECTRIQUE') return MarkerCategory.electrique;
  if (const ['Vélos', 'Vélo-cargo', 'Box à vélos', "Vélib'"].contains(regpar)) {
    return MarkerCategory.velo;
  }
  if (special.contains('moto')) return MarkerCategory.moto;
  if (regpri == 'GIG/GIC') return MarkerCategory.pmr;
  if (regpri == 'LIVRAISON') return MarkerCategory.livraison;
  if (regpri == 'AUTOCAR') return MarkerCategory.autocar;
  if (regpri == 'GRATUIT') return MarkerCategory.gratuit;
  if (regpri.contains('PAYANT')) return MarkerCategory.payant;
  return MarkerCategory.reserve;
}

class MarkerStyle {
  final Color color;
  final IconData? icon; // pictogramme…
  final String? text; // …ou texte (ex. "P")
  const MarkerStyle(this.color, {this.icon, this.text});
}

MarkerStyle markerStyleFor(MarkerCategory c) {
  switch (c) {
    case MarkerCategory.parking:
      return MarkerStyle(AppColors.markerParking, text: 'P');
    case MarkerCategory.electrique:
      return const MarkerStyle(AppColors.markerElectric, icon: Icons.ev_station);
    case MarkerCategory.velo:
      return const MarkerStyle(AppColors.markerBycicle, icon: Icons.pedal_bike);
    case MarkerCategory.moto:
      return const MarkerStyle(AppColors.markerMotorcycle, icon: Icons.two_wheeler);
    case MarkerCategory.pmr:
      return const MarkerStyle(AppColors.markerPMR, icon: Icons.accessible);
    case MarkerCategory.livraison:
      return const MarkerStyle(AppColors.markerPickup, icon: Icons.local_shipping);
    case MarkerCategory.autocar:
      return const MarkerStyle(AppColors.markerBus, icon: Icons.directions_bus);
    case MarkerCategory.gratuit:
      return const MarkerStyle(AppColors.markerFree, icon: Icons.directions_car);
    case MarkerCategory.payant:
      return const MarkerStyle(AppColors.markerPaid, icon: Icons.directions_car);
    case MarkerCategory.reserve:
      return const MarkerStyle(AppColors.markerReserved, icon: Icons.lock_outline);
  }
}

Color darken(Color c, [double amount = 0.12]) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
      .toColor();
}

class MarkerIcons {
  static const double _logical = 44; // taille affichée (dp)
  static const double _scale = 3; // rendu en haute définition

  /// Génère toutes les icônes en parallèle (à appeler une seule fois).
  static Future<Map<MarkerCategory, BitmapDescriptor>> loadAll() async {
    final entries = await Future.wait(
      MarkerCategory.values.map(
        (c) async => MapEntry(c, await _render(markerStyleFor(c))),
      ),
    );
    return Map.fromEntries(entries);
  }

  static Future<BitmapDescriptor> _render(MarkerStyle s) async {
    const size = _logical * _scale;
    const center = Offset(size / 2, size / 2);
    const radius = size / 2 - 4 * _scale; // marge pour l'ombre

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Ombre
    canvas.drawCircle(
      center.translate(0, 1.5 * _scale),
      radius,
      Paint()
        ..color = Colors.black.withAlpha(80)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5 * _scale),
    );
    // Bordure blanche puis disque coloré
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius - 2.5 * _scale, Paint()..color = s.color);

    // Pictogramme ou texte
    final icon = s.icon;
    final span = icon != null
        ? TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
              fontSize: 24 * _scale,
              color: Colors.white,
            ),
          )
        : TextSpan(
            text: s.text,
            style: const TextStyle(
              fontSize: 24 * _scale,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

    final image = await recorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      width: _logical,
      height: _logical,
    );
  }
}