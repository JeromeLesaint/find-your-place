import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../database/database_helper.dart';
import '../models/vehicle.dart';
import '../theme/app_buttons.dart';
import '../theme/app_icons.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';


/// Écran unique servant à la fois pour l'ajout et la modification.
/// Si [vehicle] est fourni, l'écran est en mode édition ; sinon en mode ajout.
class VehicleFormScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const VehicleFormScreen({super.key, this.vehicle});

  bool get isEditing => vehicle != null;

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstnameController;
  late final TextEditingController _nameController;
  late final TextEditingController _dimensionLengthController;
  late final TextEditingController _dimensionWidthController;
  late final TextEditingController _colorController;
  late final TextEditingController _notesController;

  late VehicleType _selectedType;
  bool _saving = false;
  Color pickerColor = AppColors.primaryOrange;
  Color currentColor = AppColors.primaryOrange;

  @override
  void initState() {
    super.initState();
    
   

    final v = widget.vehicle;
    _firstnameController = TextEditingController(text: v?.firstname ?? '');
    _nameController = TextEditingController(text: v?.name ?? '');
    _dimensionLengthController = TextEditingController(text: v?.dimensionLengthMeters?.toString() ?? '');
    _dimensionWidthController = TextEditingController(text: v?.dimensionWidthMeters?.toString() ?? '');
    _colorController = TextEditingController(text: v?.color ?? currentColor.toHexString());
    if (v?.color != null && v!.color!.isNotEmpty) {
      currentColor = AppColors.fromHex(v.color!);
      pickerColor = AppColors.fromHex(v.color!);
    } else {
      currentColor = AppColors.colorForType(v?.type ?? VehicleType.voiture);
      pickerColor = AppColors.colorForType(v?.type ?? VehicleType.voiture);
    }
    
    _notesController = TextEditingController(text: v?.notes ?? '');
    _selectedType = v?.type ?? VehicleType.voiture;
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _nameController.dispose();
    _dimensionLengthController.dispose();
    _dimensionWidthController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final vehicle = Vehicle(
      id: widget.vehicle?.id,
      firstname: _firstnameController.text.trim(),
      name: _nameController.text.trim(),
      type: _selectedType,
      dimensionLengthMeters: double.tryParse(_dimensionLengthController.text.trim()),
      dimensionWidthMeters: double.tryParse(_dimensionWidthController.text.trim()),
      color: _colorController.text.trim(),
      notes: _notesController.text.trim(),
    );

    try {
      if (widget.isEditing) {
        await DatabaseHelper.instance.updateVehicle(vehicle);
      } else {
        await DatabaseHelper.instance.insertVehicle(vehicle);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true); // true = succès, la liste doit se rafraîchir
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.saveVehicleError(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _fillName() {
    if (_nameController.text.trim().isEmpty) {
      String _vehicleOf = AppLocalizations.of(context)!.vehicleOf;
      final typeLabel = _selectedType.label + " " + _vehicleOf + " " +_firstnameController.text.trim();

      _nameController.text = '$typeLabel';
      if (_colorController.text.trim().isEmpty || _colorController.text.trim() == AppColors.primaryOrange.toHexString()) {
        _colorController.text = AppColors.colorForType(_selectedType).toHexString();
        currentColor = AppColors.colorForType(_selectedType);
        pickerColor = AppColors.colorForType(_selectedType);
      }
      
    }
  }

  void changeColor(Color color) {
    setState(() {
      pickerColor = color;
      _colorController.text = color.toHexString();
    });
   
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text(widget.isEditing ? AppLocalizations.of(context)!.editVehicle : AppLocalizations.of(context)!.addVehicle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _firstnameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.firstName,
                hintText: AppLocalizations.of(context)!.firstNameHint,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!.firstNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
             DropdownButtonFormField<VehicleType>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.vehicleType,
                border: OutlineInputBorder(),
              ),
              items: VehicleType.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                  _fillName();
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.vehicleName,
                hintText: AppLocalizations.of(context)!.vehicleNameHint,
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!.vehicleNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dimensionLengthController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.dimensionLength,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dimensionWidthController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.dimensionWidth,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.color
            ),
            AppCircleIconButton(
              icon: AppIcons.palette,
              tooltip: AppLocalizations.of(context)!.pickAColor,
              backgroundColor: currentColor,
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(AppLocalizations.of(context)!.pickAColor),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: pickerColor,
                          onColorChanged: changeColor,
                          enableAlpha: false,// Désactive la sélection de l'opacité
                           


                        ),
                        // Use Material color picker:
                        //
                        // child: MaterialPicker(
                        //   pickerColor: pickerColor,
                        //   onColorChanged: changeColor,
                        //   showLabel: true, // only on portrait mode
                        // ),
                        //
                        // Use Block color picker:
                        //
                        // child: BlockPicker(
                        //   pickerColor: currentColor,
                        //   onColorChanged: changeColor,
                        // ),
                        //
                        // child: MultipleChoiceBlockPicker(
                        //   pickerColors: currentColors,
                        //   onColorsChanged: changeColors,
                        // ),
                      ),
                      actions: <Widget>[
                        ElevatedButton(
                          child: Text(AppLocalizations.of(context)!.gotIt),
                          onPressed: () {
                            setState(() => currentColor = pickerColor);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
  
            );}
            ), 
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.notes,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: widget.isEditing ? AppLocalizations.of(context)!.saveChanges : AppLocalizations.of(context)!.addVehicle,
              icon: AppIcons.save,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
