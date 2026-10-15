import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:fyp_flutter_app/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ------------------------------------------------------------------ helpers

Map<String, dynamic>? asMap(dynamic v) =>
    v is Map ? v.cast<String, dynamic>() : null;

bool hasNumbers(Map<String, dynamic>? m) =>
    m != null && m.values.any((v) => v is num);

String formatPrice(AppLocalizations l10n, num v, {bool decimals = false}) {
  final withCents = decimals || v % 1 != 0;
  return NumberFormat.currency(
    locale: l10n.localeName,
    symbol: '€',
    decimalDigits: withCents ? 2 : 0,
  ).format(v);
}

String formatNumber(AppLocalizations l10n, num v) =>
    NumberFormat('0.#', l10n.localeName).format(v);

/// "tarif_special" -> "Tarif special" (repli pour les valeurs inconnues)
String humanize(String s) => sentence(s.replaceAll('_', ' '));

/// Met seulement la 1re lettre en majuscule (garde "SH Non-conforme").
String sentence(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Uri http(s) valide, ou null.
Uri? parseUrl(dynamic raw) {
  if (raw is! String) return null;
  var s = raw.trim();
  if (s.isEmpty) return null;
  if (!s.contains('://')) s = 'https://$s';
  final uri = Uri.tryParse(s);
  if (uri == null ||
      !(uri.scheme == 'http' || uri.scheme == 'https') ||
      uri.host.isEmpty) {
    return null;
  }
  return uri;
}

/// "0140469561" -> (label: "01 40 46 95 61", uri: tel:0140469561), ou null.
({String label, Uri uri})? parsePhone(dynamic raw) {
  if (raw == null) return null;
  final digits = raw.toString().replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.length < 6) return null;
  final label = RegExp(r'^0\d{9}$').hasMatch(digits)
      ? digits.replaceAllMapped(RegExp(r'(\d{2})(?=\d)'), (m) => '${m[1]} ')
      : digits;
  return (label: label, uri: Uri(scheme: 'tel', path: digits));
}

/// Traduit OUI/NON, sinon met en forme la valeur brute de l'API.
String textValue(AppLocalizations l10n, dynamic v) {
  final s = v.toString().trim();
  switch (s.toLowerCase()) {
    case 'oui':
    case 'yes':
      return l10n.valueYes;
    case 'non':
    case 'no':
      return l10n.valueNo;
  }
  return humanize(s);
}


const List<String> kParkingDurationKeys = [
  'quinze_minutes',
  'trente_minutes',
  'une_heure',
  'une_heure_trente',
  'deux_heures',
  'trois_heures',
  'quatre_heures',
  'sept_heures',
  'huit_heures',
  'neuf_heures',
  'dix_heures',
  'onze_heures',
  'douze_heures',
  'vingt_quatre_heures',
];

const List<String> kStreetDurationKeys = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'];

String parkingDurationLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'quinze_minutes':
      return l10n.durationMinutes(15);
    case 'trente_minutes':
      return l10n.durationMinutes(30);
    case 'une_heure':
      return l10n.durationHours(1);
    case 'une_heure_trente':
      return l10n.durationHoursMinutes(1, 30);
    case 'deux_heures':
      return l10n.durationHours(2);
    case 'trois_heures':
      return l10n.durationHours(3);
    case 'quatre_heures':
      return l10n.durationHours(4);
    case 'sept_heures':
      return l10n.durationHours(7);
    case 'huit_heures':
      return l10n.durationHours(8);
    case 'neuf_heures':
      return l10n.durationHours(9);
    case 'dix_heures':
      return l10n.durationHours(10);
    case 'onze_heures':
      return l10n.durationHours(11);
    case 'douze_heures':
      return l10n.durationHours(12);
    case 'vingt_quatre_heures':
      return l10n.durationHours(24);
    default:
      return humanize(key);
  }
}

String streetDurationLabel(AppLocalizations l10n, String key) {
  final n = int.tryParse(key.replaceFirst('h', ''));
  return n == null ? key : l10n.durationHours(n);
}

double distanceInMeters(LatLng a, LatLng b) {
    const r = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(b.latitude - a.latitude);
    final dLon = rad(b.longitude - a.longitude);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.latitude)) *
            math.cos(rad(b.latitude)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  String formatDistance(double m) =>
      m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';

  

// ------------------------------------------------------------------ widgets

/// Conteneur commun : hauteur limitée + scroll interne.
class InfoShell extends StatelessWidget {
  final double maxHeight;
  final List<Widget> children;
  const InfoShell({super.key, required this.maxHeight, required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Section dépliable.
class InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const InfoSection({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        dense: true,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(icon, size: 20),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        children: children,
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const InfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          const SizedBox(width: 8),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class InfoBadge extends StatelessWidget {
  final String label;
  final Color color;
  final String? svgAsset; // icône SVG (prioritaire)
  final IconData? icon; // repli si pas de SVG

  const InfoBadge({
    super.key,
    required this.label,
    required this.color,
    this.svgAsset,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Color.alphaBlend(
        color.withAlpha(40), Theme.of(context).colorScheme.surface);

    Widget? leading;
    if (svgAsset != null) {
      // Pastille blanche : les SVG sont bleu marine, ils restent lisibles
      // même en thème sombre.
      leading = Container(
        width: 24,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SvgPicture.asset(
          svgAsset!,
          semanticsLabel: label,
          errorBuilder: (_, __, ___) =>
              Icon(icon ?? Icons.help_outline, size: 16, color: color),
        ),
      );
    } else if (icon != null) {
      leading = Icon(icon, size: 16, color: color);
    } else {
      leading = SizedBox(width: 16, height: 16); // juste un petit espace
    }

    return Container(
      padding: EdgeInsets.fromLTRB(leading != null ? 4 : 10, 4, 10, 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 6)],
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }
}

/// Grille de tarifs : une cellule (durée / prix) par entrée numérique.
class TarifGrid extends StatelessWidget {
  final String title;
  final Map<String, dynamic> tarifs;
  final List<String> order; // clés, dans l'ordre d'affichage
  final String Function(String key) labelOf;
  final int columns;

  const TarifGrid({
    super.key,
    required this.title,
    required this.tarifs,
    required this.order,
    required this.labelOf,
    this.columns = 3,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final entries = order.where((k) => tarifs[k] is num).toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    const spacing = 6.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        LayoutBuilder(builder: (context, c) {
          final w = (c.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: entries.map((k) {
              final highlight = k == 'vingt_quatre_heures';
              return Container(
                width: w,
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                decoration: BoxDecoration(
                  color: highlight
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(labelOf(k),
                        style: TextStyle(
                            fontSize: 11, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(formatPrice(l10n, tarifs[k] as num, decimals: true),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}

/// Lien cliquable (site web, téléphone…).
class LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Uri uri;
  final String errorMessage;

  const LinkRow({
    super.key,
    required this.icon,
    required this.label,
    required this.uri,
    required this.errorMessage,
  });

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final ok = await launchUrl(
        uri,
        mode: uri.scheme == 'tel'
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      if (!ok) throw Exception('launchUrl a renvoyé false');
    } catch (e) {
      debugPrint('Impossible d\'ouvrir $uri : $e');
      messenger?.showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  decoration: TextDecoration.underline,
                  decorationColor: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}