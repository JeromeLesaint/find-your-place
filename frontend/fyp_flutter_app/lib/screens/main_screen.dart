import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/security.dart';
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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late GoogleMapController mapController;

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

  @override
  void initState() {
    super.initState();
    

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
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _refresh();
    _initMarkers();
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

  Future<http.Response> fetchPlaces() {
    final key = generateUniqueId(dotenv.env['SECRET_PHRASE']!);
    return http.get(
      Uri.parse(
        '$apiUrl?action=searchbydistance&lat=${_center.latitude}&lon=${_center.longitude}&key=$key',
      ),
    );
  }

  void _refreshMarkers(Vehicle vehicle) {
    // TODO: filtrer/recharger les marqueurs en fonction du véhicule
    // sélectionné (ex : rayon d'action différent selon voiture/vélo/utilitaire).
  }

  void _initMarkers() {
    final Map<MarkerId, Marker> updated = {};

    for (final place in _places) {
      final geoPoint = place['geo_point_2d'];
      if (geoPoint == null) continue;

      final lat = (geoPoint['lat'] as num).toDouble();
      final lon = (geoPoint['lon'] as num).toDouble();

      // L'_id renvoyé par l'API est un objet Mongo { "$oid": "..." },
      // pas une simple valeur : il faut extraire la clé $oid.
      final rawId = place['_id'];
      final id = (rawId is Map && rawId['\$oid'] != null)
          ? rawId['\$oid'].toString()
          : rawId.toString();

      
      final typevoie = place['typevoie']?.toString() ?? '';
      final nomvoie = place['nomvoie']?.toString() ?? '';
      final regpri = place['regpri']?.toString();

      final marker = Marker(
        markerId: MarkerId(id),
        position: LatLng(lat, lon),
        infoWindow: InfoWindow(
          title: '$typevoie $nomvoie'.trim(),
          snippet: regpri,
        ),
      );
      updated[marker.markerId] = marker;
    }

    // Un seul setState pour tous les marqueurs, au lieu d'un par élément.
    setState(() {
      markers = updated;
    });
  }

  Future<void> _goToVehiclesScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const VehicleListScreen()),
    );
    if (result == true) _refresh();
  }

  Future<void> _goToInfosScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => InfosScreen()),
    );
    
  }

  void _refresh() {
    DatabaseHelper.instance.getAllVehicles().then((vehicles) {
      final items = <CircularMenuItem>[];
      
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
          onTap: _goToVehiclesScreen,
        ),
      );
  debugPrint(mounted.toString());
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
            : (decoded['results'] ?? decoded['records'] ?? []) as List<dynamic>;

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
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 16.0,
            ),
            markers: Set<Marker>.of(markers.values),
          ),
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