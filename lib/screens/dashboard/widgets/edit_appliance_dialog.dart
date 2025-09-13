import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/firebase_service.dart';
import '../../../models/appliance.dart';

class EditApplianceDialog extends StatefulWidget {
  final Appliance appliance;

  const EditApplianceDialog({
    super.key,
    required this.appliance,
  });

  @override
  State<EditApplianceDialog> createState() => _EditApplianceDialogState();
}

class _EditApplianceDialogState extends State<EditApplianceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdController = TextEditingController();
  final _applianceNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _deviceIdController.text = widget.appliance.deviceId;
    _applianceNameController.text = widget.appliance.id;
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _applianceNameController.dispose();
    super.dispose();
  }

  Future<void> _updateAppliance() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final firebaseService = context.read<FirebaseService>();
      final newDeviceId = _deviceIdController.text.trim();
      final newApplianceName = _applianceNameController.text.trim();

      // Only update if something changed
      if (newDeviceId != widget.appliance.deviceId || 
          newApplianceName != widget.appliance.id) {
        
        final success = await firebaseService.updateAppliance(
          widget.appliance.deviceId,
          widget.appliance.id,
          newDeviceId,
          newApplianceName,
        );

        setState(() {
          _isLoading = false;
        });

        if (success && mounted) {
          Navigator.of(context).pop();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update appliance. Please try again.'),
            ),
          );
        }
      } else {
        // Nothing changed, just close the dialog
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Appliance'),
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
          onPressed: _isLoading ? null : _updateAppliance,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}