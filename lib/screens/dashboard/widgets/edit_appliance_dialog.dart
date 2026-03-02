import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/appliance.dart';
import '../../../services/firebase_service.dart';

class EditApplianceDialog extends StatefulWidget {
  final Appliance appliance;

  const EditApplianceDialog({super.key, required this.appliance});

  @override
  State<EditApplianceDialog> createState() => _EditApplianceDialogState();
}

class _EditApplianceDialogState extends State<EditApplianceDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _voltageController;
  late TextEditingController _calibrationController;
  late TextEditingController _peakCurrentController;
  late TextEditingController _gpioPinController;

  bool _enabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final config = widget.appliance.config;

    _nameController =
        TextEditingController(text: widget.appliance.name);
    _voltageController =
        TextEditingController(text: config.voltage.toString());
    _calibrationController =
        TextEditingController(text: config.calibration.toString());
    _peakCurrentController =
        TextEditingController(text: config.peakCurrent.toString());
    _gpioPinController =
        TextEditingController(text: config.gpioPin.toString());
    _enabled = config.enabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _voltageController.dispose();
    _calibrationController.dispose();
    _peakCurrentController.dispose();
    _gpioPinController.dispose();
    super.dispose();
  }

  Future<void> _updateAppliance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final firebaseService = context.read<FirebaseService>();

    final voltage =
        double.tryParse(_voltageController.text.trim()) ?? 230.0;
    final calibration =
        double.tryParse(_calibrationController.text.trim()) ?? 1.0;
    final peakCurrent =
        double.tryParse(_peakCurrentController.text.trim()) ?? 0.0;
    final gpioPin =
        int.tryParse(_gpioPinController.text.trim()) ?? 0;

    final deviceId = widget.appliance.deviceId!;
    final applianceId = widget.appliance.id;

    try {
      await firebaseService.updateApplianceConfig(
        deviceId: deviceId,
        applianceId: applianceId,
        voltage: voltage,
        calibration: calibration,
        peakCurrent: peakCurrent,
        gpioPin: gpioPin,
        enabled: _enabled,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update failed')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Appliance Config'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Appliance Name (Read Only)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _voltageController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Voltage (V)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _calibrationController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Calibration'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _peakCurrentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Peak Current (A)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gpioPinController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'GPIO Pin'),
              ),
              SwitchListTile(
                title: const Text('Enabled'),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _updateAppliance,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Update'),
        ),
      ],
    );
  }
}