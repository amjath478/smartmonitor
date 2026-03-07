

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
      final voltage = double.parse(_voltageController.text.trim());
      final calibration = double.parse(_calibrationController.text.trim());
      final peakCurrent = double.parse(_peakCurrentController.text.trim());
      final gpioPin = int.parse(_gpioPinController.text.trim());
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
                    if (value.trim().isEmpty) {
                      return 'Device ID cannot be only whitespace';
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
                    helperText: 'Typical: 100-240V',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter voltage';
                    }
                    final voltage = double.tryParse(value);
                    if (voltage == null) {
                      return 'Please enter a valid number';
                    }
                    if (voltage < 10) {
                      return 'Voltage must be at least 10V';
                    }
                    if (voltage > 500) {
                      return 'Voltage cannot exceed 500V';
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
                    helperText: 'Max safe current limit',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter peak current';
                    }
                    final current = double.tryParse(value);
                    if (current == null) {
                      return 'Please enter a valid number';
                    }
                    if (current <= 0) {
                      return 'Peak current must be greater than 0';
                    }
                    if (current > 100) {
                      return 'Peak current should not exceed 100A';
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
                    helperText: 'ESP32: 0-39 (avoid 6-11, 16-17)',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter GPIO pin';
                    }
                    final pin = int.tryParse(value);
                    if (pin == null) {
                      return 'Please enter a valid integer';
                    }
                    if (pin < 0 || pin > 39) {
                      return 'GPIO pin must be 0-39 for ESP32';
                    }
                    if ([6, 7, 8, 9, 10, 11, 16, 17].contains(pin)) {
                      return 'GPIO $pin is reserved for flash memory';
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