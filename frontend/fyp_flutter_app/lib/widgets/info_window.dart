import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ===========================================================================
// 1) InfoWindowWidget : l'apparence de la bulle (100 % paramétrable)
// ===========================================================================

/// Bulle d'information avec en-tête, contenu, actions et petite flèche.
///
/// Tous les blocs sont optionnels : fournissez seulement ce dont vous avez
/// besoin. Pour un contenu totalement libre, passez simplement [content].
class InfoWindowWidget extends StatelessWidget {
  const InfoWindowWidget({
    super.key,
    // Contenu
    this.title,
    this.subtitle,
    this.leading,
    this.content,
    this.actions = const [],
    // Dimensions
    this.width = 280,
    this.maxHeight,
    // Style de la bulle
    this.backgroundColor = Colors.white,
    this.borderRadius = 16,
    this.elevation = 8,
    this.shadowColor,
    // Style de l'en-tête
    this.headerColor,
    this.headerGradient,
    this.headerForegroundColor,
    this.headerPadding = const EdgeInsets.fromLTRB(14, 12, 6, 12),
    this.titleStyle,
    this.subtitleStyle,
    // Corps
    this.contentPadding = const EdgeInsets.all(14),
    // Fermeture / interaction
    this.showCloseButton = true,
    this.onClose,
    this.onTap,
    // Flèche
    this.showPointer = true,
    this.pointerSize = const Size(20, 10),
  });

  /// Titre affiché dans l'en-tête.
  final String? title;

  /// Sous-titre (adresse, catégorie...) sous le titre.
  final String? subtitle;

  /// Widget à gauche du titre (icône, image, avatar...).
  final Widget? leading;

  /// Contenu libre sous l'en-tête.
  final Widget? content;

  /// Boutons d'action affichés en bas (alignés en colonne, pleine largeur).
  final List<Widget> actions;

  final double width;

  /// Si défini, le corps devient défilant au-delà de cette hauteur.
  final double? maxHeight;

  final Color backgroundColor;
  final double borderRadius;
  final double elevation;
  final Color? shadowColor;

  /// Couleur unie de l'en-tête (ignorée si [headerGradient] est fourni).
  final Color? headerColor;
  final Gradient? headerGradient;

  /// Couleur du texte/icônes de l'en-tête. Par défaut : blanc si l'en-tête
  /// a un fond, sinon la couleur de texte du thème.
  final Color? headerForegroundColor;
  final EdgeInsets headerPadding;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  final EdgeInsets contentPadding;

  final bool showCloseButton;
  final VoidCallback? onClose;
  final VoidCallback? onTap;

  final bool showPointer;
  final Size pointerSize;

  bool get _aUnEnTete =>
      title != null || subtitle != null || leading != null || showCloseButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fondEnTete = headerColor != null || headerGradient != null;
    final fg = headerForegroundColor ??
        (fondEnTete ? Colors.white : theme.colorScheme.onSurface);

    final enTete = _aUnEnTete
        ? Container(
            padding: headerPadding,
            decoration: BoxDecoration(
              color: headerGradient == null ? headerColor : null,
              gradient: headerGradient,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  IconTheme(
                    data: IconThemeData(color: fg),
                    child: leading!,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle ??
                              TextStyle(
                                color: fg,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: subtitleStyle ??
                                TextStyle(
                                  color: fg.withValues(alpha: 0.85),
                                  fontSize: 12.5,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (showCloseButton)
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close, color: fg, size: 20),
                    tooltip: 'Fermer',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          )
        : null;

    final corps = Padding(
      padding: contentPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?content,
          if (content != null && actions.isNotEmpty) const SizedBox(height: 12),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            actions[i],
          ],
        ],
      ),
    );

    final aUnCorps = content != null || actions.isNotEmpty;

    Widget colonne = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?enTete,
        if (aUnCorps)
          // Défilement uniquement si une hauteur max est fixée
          // (Flexible exige une contrainte de hauteur bornée).
          if (maxHeight != null)
            Flexible(child: SingleChildScrollView(child: corps))
          else
            corps,
      ],
    );

    if (maxHeight != null) {
      colonne = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        child: colonne,
      );
    }

    final bulle = Material(
      color: backgroundColor,
      elevation: elevation,
      shadowColor: shadowColor,
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: colonne),
    );

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          bulle,
          if (showPointer)
            CustomPaint(
              size: pointerSize,
              painter: _PointerPainter(
                color: backgroundColor,
                elevation: elevation / 2,
                shadowColor: shadowColor ?? Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  _PointerPainter({
    required this.color,
    required this.elevation,
    required this.shadowColor,
  });

  final Color color;
  final double elevation;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawShadow(path, shadowColor, elevation, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PointerPainter old) =>
      old.color != color ||
      old.elevation != elevation ||
      old.shadowColor != shadowColor;
}

// ===========================================================================
// 2) InfoWindowController : affiche / masque / suit le marker
// ===========================================================================

/// Gère la position de l'InfoWindow sur la carte.
///
/// À brancher sur la GoogleMap :
/// - `onMapCreated`  → [onMapCreated]
/// - `onCameraMove`  → [onCameraMove]
/// - `onCameraIdle`  → [refresh]
/// - `onTap` (carte) → [hide] si vous voulez fermer au tap sur la carte
class InfoWindowController extends ChangeNotifier {
  GoogleMapController? _map;
  LatLng? _position;
  Widget? _child;
  Offset? _offset; // position écran (pixels logiques) du point ancré

  /// Renseigné automatiquement par [InfoWindowLayer].
  double devicePixelRatio = 1;

  bool get isVisible => _child != null && _offset != null;
  LatLng? get position => _position;
  Widget? get child => _child;
  Offset? get screenOffset => _offset;

  void onMapCreated(GoogleMapController controller) => _map = controller;

  Future<void> show({
    required LatLng position,
    required Widget child,
    bool centerCamera = false,
  }) async {
    _position = position;
    _child = child;
    if (centerCamera) {
      await _map?.animateCamera(CameraUpdate.newLatLng(position));
    }
    await refresh();
  }

  void hide() {
    if (_child == null) return;
    _child = null;
    _position = null;
    _offset = null;
    notifyListeners();
  }

  Future<void> onCameraMove(CameraPosition _) => refresh();

  /// Recalcule la position écran du point ancré.
  Future<void> refresh() async {
    final map = _map;
    final pos = _position;
    if (map == null || pos == null || _child == null) return;

    final sc = await map.getScreenCoordinate(pos);
    // Android renvoie des pixels physiques, iOS des pixels logiques.
    final ratio = defaultTargetPlatform == TargetPlatform.android
        ? devicePixelRatio
        : 1.0;
    _offset = Offset(sc.x / ratio, sc.y / ratio);
    notifyListeners();
  }
}

// ===========================================================================
// 3) InfoWindowLayer : à placer dans un Stack au-dessus de la GoogleMap
// ===========================================================================

class InfoWindowLayer extends StatelessWidget {
  const InfoWindowLayer({
    super.key,
    required this.controller,
    this.verticalOffset = 20,
    this.horizontalOffset = 0,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  final InfoWindowController controller;

  /// Décalage vers le haut pour que la flèche touche le haut du marker
  /// (≈ moitié de la hauteur de l'icône si l'ancre est au centre).
  final double verticalOffset;
  final double horizontalOffset;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    controller.devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    return SizedBox.expand(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final offset = controller.screenOffset;
          final child = controller.child;

          return Stack(
            children: [
              if (child != null && offset != null)
                Positioned(
                  left: offset.dx + horizontalOffset,
                  top: offset.dy - verticalOffset,
                  // Centre horizontalement et place le bas de la bulle
                  // (pointe de la flèche) sur le point.
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -1),
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(controller.position),
                      tween: Tween(begin: 0, end: 1),
                      duration: animationDuration,
                      builder: (_, t, c) => Opacity(opacity: t, child: c),
                      child: child,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ===========================================================================
// Exemple d'utilisation
// ===========================================================================
//
// class _PageCarteState extends State<PageCarte> {
//   final _infoWindow = InfoWindowController();
//
//   @override
//   void dispose() {
//     _infoWindow.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: const CameraPosition(
//               target: LatLng(48.8667, 2.3333),
//               zoom: 12,
//             ),
//             onMapCreated: _infoWindow.onMapCreated,
//             onCameraMove: _infoWindow.onCameraMove,
//             onCameraIdle: _infoWindow.refresh,
//             onTap: (_) => _infoWindow.hide(),
//             markers: {
//               Marker(
//                 markerId: const MarkerId('p1'),
//                 position: const LatLng(48.8584, 2.2945),
//                 anchor: const Offset(0.5, 0.5),
//                 onTap: () => _infoWindow.show(
//                   position: const LatLng(48.8584, 2.2945),
//                   child: InfoWindowWidget(
//                     title: 'Parking Tour Eiffel',
//                     subtitle: 'Avenue Gustave Eiffel · Paris 7e',
//                     leading: const Icon(Icons.local_parking),
//                     headerGradient: const LinearGradient(
//                       colors: [Color(0xFF075D67), Color(0xFF008C95)],
//                     ),
//                     content: const Text('120 places · Tarif 1 h : 4,80 €'),
//                     actions: [
//                       FilledButton.icon(
//                         onPressed: () {},
//                         icon: const Icon(Icons.directions),
//                         label: const Text('Y aller'),
//                       ),
//                     ],
//                     maxHeight: 320,
//                     onClose: _infoWindow.hide,
//                   ),
//                 ),
//               ),
//             },
//           ),
//           // Doit venir APRÈS la GoogleMap dans le Stack
//           InfoWindowLayer(controller: _infoWindow, verticalOffset: 18),
//         ],
//       ),
//     );
//   }
// }
