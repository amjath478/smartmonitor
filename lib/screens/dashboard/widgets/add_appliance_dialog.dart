

//4th commit
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/firebase_service.dart';

class AddApplianceDialog extends StatefulWidget {
  const AddApplianceDialog({super.key});

  @override
  State<AddApplianceDialog> createState() => _AddApplianceDialogState();
}

class _AddApplianceDialogState extends State<AddApplianceDialog> {
  final _formKey = GlobalKey<FormState>();

  // basic identification
  final _deviceIdController = TextEditingController();
  final _applianceNameController = TextEditingController();

  // configuration controllers with default values
  final _voltageController = TextEditingController(text: '230.0');
  final _calibrationController = TextEditingController(text: '1.0');
  final _peakCurrentController = TextEditingController();
  final _gpioPinController = TextEditingController();

  bool _enabled = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _deviceIdController.dispose();
    _applianceNameController.dispose();
    _voltageController.dispose();
    _calibrationController.dispose();
    _peakCurrentController.dispose();
    _gpioPinController.dispose();
    super.dispose();
  }

  Future<void> _addAppliance() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final firebaseService = context.read<FirebaseService>();
final voltage =
    double.tryParse(_voltageController.text.trim()) ?? 230.0;

final calibration =
    double.tryParse(_calibrationController.text.trim()) ?? 1.0;

final peakCurrent =
    double.tryParse(_peakCurrentController.text.trim()) ?? 0.0;

final gpioPin =
    int.tryParse(_gpioPinController.text.trim()) ?? 0;
      final enabled = _enabled;

      final success = await firebaseService.addAppliance(
        _deviceIdController.text.trim(),
        _applianceNameController.text.trim(),
        voltage: voltage,
        calibration: calibration,
        peakCurrent: peakCurrent,
        gpioPin: gpioPin,
        enabled: enabled,
      );

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add appliance. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // inset amount when keyboard is visible; used to pad the scroll view
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AlertDialog(
      scrollable: true,
      title: const Text('Add New Appliance'),
      content: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _deviceIdController,
                  decoration: const InputDecoration(
                    labelText: 'Device ID (ESP ID)',
                    prefixIcon: Icon(Icons.router),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter device ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _applianceNameController,
                  decoration: const InputDecoration(
                    labelText: 'Appliance Name',
                    prefixIcon: Icon(Icons.electrical_services),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter appliance name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _voltageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Voltage (V)',
                    prefixIcon: Icon(Icons.flash_on),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter voltage';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _calibrationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calibration',
                    prefixIcon: Icon(Icons.tune),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter calibration';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _peakCurrentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Peak Current (A)',
                    prefixIcon: Icon(Icons.trending_up),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter peak current';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _gpioPinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'GPIO Pin',
                    prefixIcon: Icon(Icons.pin),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter GPIO pin';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid integer';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enabled'),
                  value: _enabled,
                  onChanged: (val) {
                    setState(() {
                      _enabled = val;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _addAppliance,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}