/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/firebase_service.dart';

class AddApplianceDialog extends StatefulWidget {
  const AddApplianceDialog({super.key});

  @override
  State<AddApplianceDialog> createState() => _AddApplianceDialogState();
}

class _AddApplianceDialogState extends State<AddApplianceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdController = TextEditingController();
  final _applianceNameController = TextEditingController();
  final _currentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _deviceIdController.dispose();
    _applianceNameController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  Future<void> _addAppliance() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final firebaseService = context.read<FirebaseService>();
      final success = await firebaseService.addAppliance(
        _deviceIdController.text.trim(),
        _applianceNameController.text.trim(),
        double.parse(_currentController.text),
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
    return AlertDialog(
      title: const Text('Add New Appliance'),
      content: Form(
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
              controller: _currentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Initial Current (A)',
                prefixIcon: Icon(Icons.electric_bolt),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter current value';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ],
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
*/
//3-commit
/* 4th
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
  final _deviceIdController = TextEditingController();
  final _applianceNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _deviceIdController.dispose();
    _applianceNameController.dispose();
    super.dispose();
  }

  Future<void> _addAppliance() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final firebaseService = context.read<FirebaseService>();
      final success = await firebaseService.addAppliance(
        _deviceIdController.text.trim(),
        _applianceNameController.text.trim(),
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
    return AlertDialog(
      title: const Text('Add New Appliance'),
      content: Form(
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
          ],
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
*/
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
  final _deviceIdController = TextEditingController();
  final _applianceNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _deviceIdController.dispose();
    _applianceNameController.dispose();
    super.dispose();
  }

  Future<void> _addAppliance() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final firebaseService = context.read<FirebaseService>();
      final success = await firebaseService.addAppliance(
        _deviceIdController.text.trim(),
        _applianceNameController.text.trim(),
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
    return AlertDialog(
      title: const Text('Add New Appliance'),
      content: Form(
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
          ],
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