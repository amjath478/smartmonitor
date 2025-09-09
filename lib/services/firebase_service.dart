import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/appliance.dart';

class FirebaseService extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Device> _devices = [];
  bool _isLoading = false;
  String? _error;

  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasPeakWarnings {
    return _devices.any((device) => device.hasPeakAppliances);
  }

  List<Appliance> get allAppliances {
    return _devices.expand((device) => device.appliances).toList();
  }

  Stream<List<Device>> getDevicesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _database
        .child('users/${user.uid}/devices')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Device>[];

      final devices = <Device>[];
      
      data.forEach((deviceKey, deviceValue) {
        final deviceData = deviceValue as Map<dynamic, dynamic>?;
        if (deviceData == null) return;

        final appliances = <Appliance>[];
        final appliancesData = deviceData['appliances'] as Map<dynamic, dynamic>?;
        
        if (appliancesData != null) {
          appliancesData.forEach((applianceKey, applianceValue) {
            final applianceMap = Map<String, dynamic>.from(applianceValue as Map);
            appliances.add(Appliance.fromMap(
              applianceMap,
              applianceKey.toString(),
              deviceKey.toString(),
            ));
          });
        }

        devices.add(Device(
          id: deviceKey.toString(),
          appliances: appliances,
        ));
      });

      return devices;
    });
  }

  Future<bool> addAppliance(String deviceId, String applianceName, double initialCurrent) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final appliance = Appliance(
        id: applianceName,
        deviceId: deviceId,
        current: initialCurrent,
        peak: false,
        timestamp: DateTime.now(),
      );

      await _database
          .child('users/${user.uid}/devices/$deviceId/appliances/$applianceName')
          .set(appliance.toMap());

      return true;
    } catch (e) {
      _error = 'Failed to add appliance: $e';
      notifyListeners();
      return false;
    }
  }

  Stream<List<Appliance>> getApplianceHistoryStream(String deviceId, String applianceId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    // For history, we'll listen to the current appliance data
    // In a real implementation, you might want to store historical data separately
    return _database
        .child('users/${user.uid}/devices/$deviceId/appliances/$applianceId')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Appliance>[];

      // For now, return current data as a single item list
      // In production, you'd query historical records
      final appliance = Appliance.fromMap(
        Map<String, dynamic>.from(data),
        applianceId,
        deviceId,
      );
      
      return [appliance];
    });
  }

  Future<void> refreshData() async {
    // This method can be used to manually refresh data if needed
    notifyListeners();
  }
}