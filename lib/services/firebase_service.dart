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

  // ==============================
  // STREAM DEVICES (FIXED PATH)
  // ==============================

  Stream<List<Device>> getDevicesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _database
        .child('users')
        .child(user.uid)
        .child('devices')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Device>[];

      final devices = <Device>[];

      data.forEach((deviceKey, deviceValue) {
        final deviceData = deviceValue as Map<dynamic, dynamic>?;
        if (deviceData == null) return;

        final appliances = <Appliance>[];
        final appliancesData =
            deviceData['appliances'] as Map<dynamic, dynamic>?;

        if (appliancesData != null) {
          appliancesData.forEach((applianceKey, applianceValue) {
            final applianceMap =
                Map<String, dynamic>.from(applianceValue as Map);

            appliances.add(Appliance.fromMap(
              applianceMap,
              applianceKey.toString(),
              deviceId: deviceKey.toString(),
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

  // ==============================
  // ADD APPLIANCE (FIXED)
  // ==============================

  Future<bool> addAppliance(
    String deviceId,
    String applianceName, {
    double voltage = 230.0,
    double calibration = 1.0,
    double peakCurrent = 0.0,
    int gpioPin = 0,
    bool enabled = true,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final appliance = Appliance(
        id: applianceName,
        deviceId: deviceId,
        name: applianceName,
        config: ApplianceConfig(
          voltage: voltage,
          calibration: calibration,
          peakCurrent: peakCurrent,
          gpioPin: gpioPin,
          enabled: enabled,
        ),
        live: const ApplianceLive(),
        stats: const ApplianceStats(),
      );

      await _database
          .child('users')
          .child(user.uid)
          .child('devices')
          .child(deviceId)
          .child('appliances')
          .child(applianceName)
          .set(appliance.toMap());

      return true;
    } catch (e) {
      _error = 'Failed to add appliance: $e';
      notifyListeners();
      return false;
    }
  }

  // ==============================
  // DELETE APPLIANCE (FIXED)
  // ==============================

  Future<bool> deleteAppliance(
      String deviceId, String applianceName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _database
          .child('users')
          .child(user.uid)
          .child('devices')
          .child(deviceId)
          .child('appliances')
          .child(applianceName)
          .remove();

      return true;
    } catch (e) {
      _error = 'Failed to delete appliance: $e';
      notifyListeners();
      return false;
    }
  }

  // ==============================
  // UPDATE APPLIANCE (FIXED)
  // ==============================

  Future<bool> updateAppliance(
    String oldDeviceId,
    String oldApplianceName,
    String newDeviceId,
    String newApplianceName,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _database
          .child('users')
          .child(user.uid)
          .child('devices')
          .child(oldDeviceId)
          .child('appliances')
          .child(oldApplianceName)
          .get();

      if (snapshot.exists) {
        final applianceData = Map<String, dynamic>.from(snapshot.value as Map);
        final existing = Appliance.fromMap(
          applianceData,
          oldApplianceName,
          deviceId: oldDeviceId,
        );

        final updated = Appliance(
          id: newApplianceName,
          deviceId: newDeviceId,
          name: existing.name,
          config: existing.config,
          live: existing.live,
          stats: existing.stats,
        );

        await _database
            .child('users')
            .child(user.uid)
            .child('devices')
            .child(newDeviceId)
            .child('appliances')
            .child(newApplianceName)
            .set(updated.toMap());

        if (oldDeviceId != newDeviceId || oldApplianceName != newApplianceName) {
          await _database
              .child('users')
              .child(user.uid)
              .child('devices')
              .child(oldDeviceId)
              .child('appliances')
              .child(oldApplianceName)
              .remove();
        }

        return true;
      }

      return false;
    } catch (e) {
      _error = 'Failed to update appliance: $e';
      notifyListeners();
      return false;
    }
  }

  // ==============================
  // GET APPLIANCE HISTORY
  // ==============================

  Stream<List<Appliance>> getApplianceHistoryStream(
    String deviceId,
    String applianceId,
  ) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _database
        .child('users')
        .child(user.uid)
        .child('devices')
        .child(deviceId)
        .child('appliances')
        .child(applianceId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final appliance = Appliance.fromMap(
          Map<String, dynamic>.from(event.snapshot.value as Map),
          applianceId,
          deviceId: deviceId,
        );
        return [appliance];
      }
      return <Appliance>[];
    });
  }
  // ==============================
  // GET DAILY ENERGY HISTORY
  // ==============================

  Stream<Map<String, double>> getDailyEnergyHistory(
    String deviceId,
    String applianceId,
  ) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value({});

    return _database
        .child('users')
        .child(user.uid)
        .child('devices')
        .child(deviceId)
        .child('appliances')
        .child(applianceId)
        .child('history')
        .child('daily')
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>,
        );
        return data.map((key, value) => MapEntry(
          key,
          (value is num) ? value.toDouble() : 0.0,
        ));
      }
      return <String, double>{};
    });
  }

  // ==============================
  // GET MONTHLY ENERGY HISTORY
  // ==============================

  Stream<Map<String, double>> getMonthlyEnergyHistory(
    String deviceId,
    String applianceId,
  ) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value({});

    return _database
        .child('users')
        .child(user.uid)
        .child('devices')
        .child(deviceId)
        .child('appliances')
        .child(applianceId)
        .child('history')
        .child('monthly')
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>,
        );
        return data.map((key, value) => MapEntry(
          key,
          (value is num) ? value.toDouble() : 0.0,
        ));
      }
      return <String, double>{};
    });
  }
// ==============================
// UPDATE APPLIANCE CONFIG (FOR EDIT DIALOG)
// ==============================

Future<void> updateApplianceConfig({
  required String deviceId,
  required String applianceId,
  required double voltage,
  required double calibration,
  required double peakCurrent,
  required int gpioPin,
  required bool enabled,
}) async {
  try {
    final user = _auth.currentUser;
    if (user == null) return;

    await _database
        .child('users')
        .child(user.uid)
        .child('devices')
        .child(deviceId)
        .child('appliances')
        .child(applianceId)
        .child('config')
        .update({
      'voltage': voltage,
      'calibration': calibration,
      'peakCurrent': peakCurrent,
      'gpioPin': gpioPin,
      'enabled': enabled,
    });

  } catch (e) {
    _error = 'Failed to update appliance config: $e';
    notifyListeners();
  }
}




  // ==============================
  // SIMPLE REFRESH
  // ==============================

  Future<void> refreshData() async {
    notifyListeners();
  }
}

