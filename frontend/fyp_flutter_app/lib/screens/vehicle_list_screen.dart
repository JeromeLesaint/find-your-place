import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/vehicle.dart';
import '../theme/app_buttons.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import 'vehicle_form_screen.dart';
import '../l10n/app_localizations.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  late Future<List<Vehicle>> _vehiclesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _vehiclesFuture = DatabaseHelper.instance.getAllVehicles();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _goToAddScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
    );
    if (result == true) _refresh();
  }

  Future<void> _goToEditScreen(Vehicle vehicle) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => VehicleFormScreen(vehicle: vehicle)),
    );
    if (result == true) _refresh();
  }

  Future<void> _confirmDelete(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteVehicle),
        content: Text(AppLocalizations.of(context)!.deleteVehicleConfirmation(vehicle.name)),
        actions: [
          AppSecondaryButton(
            label: AppLocalizations.of(context)!.cancel,
            expand: false,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppDestructiveButton(
            label: AppLocalizations.of(context)!.delete,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && vehicle.id != null) {
      await DatabaseHelper.instance.deleteVehicle(vehicle.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.vehicleDeleted(vehicle.name))),
      );
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.myVehicles)),
      body: FutureBuilder<List<Vehicle>>(
        future: _vehiclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(AppLocalizations.of(context)!.loadingVehiclesError(snapshot.error.toString())),
            );
          }

          final vehicles = snapshot.data ?? [];

          if (vehicles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppIcons.directionsCarFilledOutlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.noVehiclesRegistered,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.addYourFirstVehicle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: vehicles.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return Dismissible(
                  key: ValueKey(vehicle.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await _confirmDelete(vehicle);
                    return false; // on gère la suppression manuellement
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Icon(
                      AppIcons.delete,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          vehicle.color != null && vehicle.color!.isNotEmpty
                              ? AppColors.fromHex(vehicle.color!)
                              : AppColors.colorForType(vehicle.type),
                      child: Icon(
                        AppIcons.iconForType(vehicle.type),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(vehicle.name),
                    subtitle: Text(
                      [
                        vehicle.type.label,
                        vehicle.firstname,
                       
                      ].where((e) => e != null && e.isNotEmpty).join(' · '),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppCircleIconButton(
                          icon: AppIcons.edit,
                          tooltip: AppLocalizations.of(context)!.edit,
                          backgroundColor: AppColors.primaryOrange,
                          onPressed: () => _goToEditScreen(vehicle),
                        ),
                        const SizedBox(width: 8),
                        AppCircleIconButton(
                          icon: AppIcons.delete,
                          tooltip: AppLocalizations.of(context)!.delete,
                          backgroundColor: AppColors.darkRust,
                          onPressed: () => _confirmDelete(vehicle),
                        ),
                      ],
                    ),
                    onTap: () => _goToEditScreen(vehicle),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: AppGradientFab(
        label: AppLocalizations.of(context)!.add,
        onPressed: _goToAddScreen,
      ),
    );
  }
}
