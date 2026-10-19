import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fyp_flutter_app/l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:circular_menu/circular_menu.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../database/database_helper.dart';
import '../models/vehicle.dart';
import '../services/location_permission_service.dart';
import 'package:http/http.dart' as http;
import 'vehicle_list_screen.dart';
import 'infos_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/info_window.dart';
import '../widgets/parking_details.dart';
import '../widgets/street_details.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/marker_icons.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late GoogleMapController mapController;
  final _infoWindow = InfoWindowController();
  final LatLng _center = const LatLng(48.85341, 2.3488);

  List<CircularMenuItem> _menuItems = [];
  GlobalKey<CircularMenuState> _menuKey = GlobalKey<CircularMenuState>();
  List<dynamic> _places = [];
  final apiUrl = dotenv.env['API_URL'];
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  StreamSubscription<Position>? _positionSubscription;

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  Map<MarkerCategory, BitmapDescriptor> _markerIcons = {};
  



  @override
  void initState() {
    super.initState();
    
    MarkerIcons.loadAll().then((icons) {
      if (!mounted) return;
      setState(() => _markerIcons = icons);
      _initMarkers(); // régénère les marqueurs une fois les icônes prêtes
    }).catchError((e) => debugPrint('Erreur génération icônes: $e'));

    // Abonnement unique au flux de position (au lieu d'un getter qui
    // recréerait un nouvel abonnement à chaque appel).
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position? position) {
      debugPrint(position == null
          ? 'Unknown'
          : '${position.latitude}, ${position.longitude}');
    });
  }

  @override
  void dispose() {
    _infoWindow.dispose();
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _infoWindow.onMapCreated(controller);
    _refresh();
    
    LocationPermissionService.getCurrentPosition().then((position) {
      /*mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );*/
    }).catchError((error) {
      debugPrint('Error determining position: $error');
    });
  }

  Future<void> openRoute(LatLng p) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}&travelmode=driving',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<http.Response> fetchPlaces() async {
    final response = await http.get(
      Uri.parse('${apiUrl!}?action=searchbydistance&lat=${_center.latitude}&lon=${_center.longitude}'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json', 'App-Id': dotenv.env['APP_ID']!, 'App-Key': dotenv.env['APP_KEY']!},
    );
    debugPrint('fetchPlaces() response: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return response;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load places: ${response.statusCode}');
    }
  }

  void _refreshMarkers(Vehicle vehicle) {
    // TODO: filtrer/recharger les marqueurs en fonction du véhicule
    // sélectionné (ex : rayon d'action différent selon voiture/vélo/utilitaire).
  }

  void _initMarkers() {
    
    final updated = <MarkerId, Marker>{};
    final l10n = AppLocalizations.of(context)!;
    var skipped = 0;

    for (var i = 0; i < _places.length; i++) {
      try {
        final place = _places[i] as Map<String, dynamic>;
        final category = markerCategoryFor(place);
        final style = markerStyleFor(category);
        final isParking = category == MarkerCategory.parking;

        // --- Coordonnées : emplacement différent selon le type ---
        final Map? gp = isParking ? (place['geolocalisation']?['point_geographique']) : place['geo_point_2d'];
        if (gp == null || gp['lat'] == null || gp['lon'] == null) {
          skipped++;
          debugPrint('Sans coordonnées #$i (${place['type_resultat']})');
          continue;
        }
        final pos = LatLng((gp['lat'] as num).toDouble(), (gp['lon'] as num).toDouble());

        // --- Id ---
        final rawId = place['_id'];
        final id = (rawId is Map && rawId[r'$oid'] != null)
            ? rawId[r'$oid'].toString()
            : 'place_$i';

        // --- Contenu de l'info-bulle ---
        late final String title, subtitle;
        late final Widget content;

        if (isParking) {
          final info = place['informations_generales'] as Map? ?? {};
          title = info['nom']?.toString() ?? l10n.parkingDefaultTitle;
          subtitle = info['adresse']?.toString() ?? l10n.noProvidedAddress;
          content = ParkingDetails(place: place, origine: _center, position: pos);
        } else {
          final rue = [place['numvoie'], place['typevoie'], place['nomvoie']]
              .where((p) => p != null && p != '')
              .join(' ');
          title = rue.isEmpty ? l10n.noProvidedAddress : rue;
          subtitle = l10n.districtOfParis(place['arrond']);
          content = StreetDetails(place: place, origine: _center, position: pos);
        }

        updated[MarkerId(id)] = Marker(
          markerId: MarkerId(id),
          position: pos,
          icon: _markerIcons[category] ?? BitmapDescriptor.defaultMarker,
          onTap: () => _infoWindow.show(
            position: pos,
            child: InfoWindowWidget(
              title: title,
              subtitle: subtitle,
              leading: Icon(style.icon ?? Icons.local_parking),
              headerGradient: const LinearGradient(
                colors: [Color(0xFF075D67), Color(0xFF008C95)],
              ),
              content: content,
              actions: [
                FilledButton.icon(
                  onPressed: () {
                    openRoute(pos);
                  },
                  icon: const Icon(Icons.directions),
                  label: Text(l10n.goThere),
                ),
              ],
              maxHeight: isParking ? 480 : 530,
              onClose: _infoWindow.hide,
            ),
          ),
        );
      } catch (e, st) {
        skipped++;
        debugPrint('Erreur marqueur #$i: $e\n$st');
      }
    }

    debugPrint('Markers créés: ${updated.length}, ignorés: $skipped');
    setState(() => markers = updated);
  }

  Future<void> _goToVehiclesScreen() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const VehicleListScreen()),
    );
    _refresh();
  }

  Future<void> _goToInfosScreen() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => InfosScreen()),
    );
    
  }

  void _refresh() {
    DatabaseHelper.instance.getAllVehicles().then((vehicles) {
      final items = <CircularMenuItem>[];
      debugPrint('Loaded ${vehicles.length} vehicles from database.');
      // 1) Un item par véhicule enregistré.
      for (final vehicle in vehicles) {

       items.add(
          CircularMenuItem(
            icon: AppIcons.iconForType(vehicle.type),
            color: vehicle.color != null && vehicle.color!.isNotEmpty
                ? AppColors.fromHex(vehicle.color!)
                : AppColors.colorForType(vehicle.type),
            onTap: () => _refreshMarkers(vehicle),
          ),
        );
      }

      
      items.add(
        CircularMenuItem(
          icon: AppIcons.info,
          color: AppColors.darkRust,
          onTap: _goToInfosScreen,
        ),
      );
      items.add(
        CircularMenuItem(
          icon: AppIcons.settings,
          color: AppColors.settingsColor,
          onTap: _goToVehiclesScreen
        ),
      );
 
      if (!mounted) return;
      setState(() {
          _menuItems = items;
          _menuKey = GlobalKey<CircularMenuState>();
      });
    });

    fetchPlaces().then((response) {
      if (response.statusCode == 200) {
        
        final decoded = jsonDecode(response.body);

        final List<dynamic> places = decoded is List
            ? decoded
            : (decoded['resultats'] ?? decoded['resultats'] ?? []) as List<dynamic>;

        if (!mounted) return;
        setState(() => _places = places);
        _initMarkers();
      } else {
        debugPrint('Failed to load places: ${response.statusCode}');
      }
    }).catchError((error) {
      debugPrint('Error fetching places: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pas de MaterialApp ici : ce widget est un écran de l'application,
    // pas la racine. Le MaterialApp racine (dans main.dart) fournit déjà
    // le thème, le Navigator, etc. En imbriquer un second casse la
    // navigation et l'héritage de thème.
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            onCameraMove: _infoWindow.onCameraMove,
            onCameraIdle: _infoWindow.refresh,
            onTap: (_) => _infoWindow.hide(),
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 16.0,
            ),
            markers: Set<Marker>.of(markers.values),
          ),
          // Doit venir APRÈS la GoogleMap dans le Stack
          InfoWindowLayer(controller: _infoWindow, verticalOffset: 18),
          CircularMenu(
            alignment: Alignment.bottomCenter,
            key: _menuKey,
            toggleButtonColor: AppColors.primaryOrange,
            items: _menuItems.isEmpty
                ? [
                    CircularMenuItem(
                      icon: AppIcons.question,
                      color: AppColors.darkRust,
                      onTap: _goToInfosScreen,
                    ),
                    CircularMenuItem(
                      icon: AppIcons.settings,
                      color: AppColors.settingsColor,
                      onTap: _goToVehiclesScreen,
                    ),
                  ]
                : _menuItems,
          ),
        ],
      ),
    );
  }
}