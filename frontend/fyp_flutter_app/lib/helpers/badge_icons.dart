import 'marker_icons.dart';

class BadgeIcons {
  static const _dir = 'assets/images/badges/';
  static String _f(String name) => '$_dir$name.svg';

  /// Icône « usage » selon la catégorie (même logique que les marqueurs).
  static String usage(MarkerCategory c) => switch (c) {
        MarkerCategory.electrique => _f('type-voiture-electrique'),
        MarkerCategory.velo => _f('type-velo'),
        MarkerCategory.moto => _f('type-moto'),
        MarkerCategory.pmr => _f('type-pmr'),
        MarkerCategory.livraison => _f('type-livraison'),
        MarkerCategory.autocar => _f('type-autocar'),
        MarkerCategory.gratuit ||
        MarkerCategory.payant ||
        MarkerCategory.parking =>
          _f('type-voiture'),
        MarkerCategory.reserve => _f('regime-reserve'),
      };

  static String get paid => _f('regime-payant');
  static String get free => _f('regime-gratuit');
  static String get places => _f('nombre-places');
  static String get parity => _f('parite');
  static String get parkingLongitudinal => _f('stationnement-longitudinal');
  static String get parkingBataille => _f('stationnement-bataille');
  static String get parkingEpi => _f('stationnement-epi');
  static String get distance => _f('distance');
}