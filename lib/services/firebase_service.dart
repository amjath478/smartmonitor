// Current Realtime Database structure (added by ESP; some fields not in models):
// users/
// └── {uid}/
//     ├── gmail:      {string}   // user email address (auto-saved on registration)
//     │
//     └── devices/
//         └── {espId}/
//             └── appliances/
//                 └── {applianceName}/
//                     │
//                     ├── config/
//                     │   ├── voltage:      {float}   // mains voltage, e.g. 230.0
//                     │   ├── calibration:  {float}   // SCT multiplier, e.g. 50.0
//                     │   ├── peakCurrent:  {float}   // amps threshold for peak flag
//                     │   ├── gpioPin:      {int}     // ESP32 ADC pin number
//                     │   └── enabled:      {bool}    // true = active, false = skip
//                     │
//                     ├── live/
//                     │   ├── current:      {float}   // RMS current in amps
//                     │   ├── power:        {float}   // watts = voltage × current
//                     │   ├── peak:         {bool}    // true if current >= peakCurrent
//                     │   └── timestamp:    {int}     // epoch time of last update (IST)
//                     │
//                     ├── stats/
//                     │   ├── todayEnergy:    {float}   // kWh accumulated today
//                     │   ├── monthEnergy:    {float}   // kWh accumulated this month
//                     │   ├── LastCalcTime:   {int}     // epoch time of last calculation
//                     │   ├── lastResetDay:   {string}  // YYYY-MM-DD of last daily reset
//                     │   └── lastResetMonth: {string}  // YYYY-MM of last monthly reset
//                     │
//                     └── history/
//                         ├── daily/
//                         │   └── {YYYY-MM-DD}: {float} // kWh total for that day
//                         └── monthly/
//                             └── {YYYY-MM}:    {float} // kWh total for that month
//
// Fields may be added by ESP and not represented in models; keep this comment as a reference.

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

    // Use distinct to reduce rebuilds - only emit when appliance data
    // meaningfully changes (not on every live update)
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
    })
    .distinct((prev, next) {
      // Only emit if the list changed (simple reference check)
      if (prev.isEmpty && next.isEmpty) return true;
      if (prev.isEmpty || next.isEmpty) return false;
      // Compare appliances - use hashcode as a quick check
      // (Note: For production, implement proper Appliance equality)
      return prev[0].id == next[0].id &&
             prev[0].config.hashCode == next[0].config.hashCode &&
             prev[0].stats.hashCode == next[0].stats.hashCode;
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

    // Use distinct with deep map equality to avoid emitting identical
    // history maps when unrelated live fields update; this prevents
    // unnecessary rebuilds and flicker in the history page.
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
    }).distinct((prev, next) => mapEquals(prev, next));
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
    }).distinct((prev, next) => mapEquals(prev, next));
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
  // REFRESH DATA FROM FIREBASE
  // ==============================

  Future<void> refreshData() async {
    try {
      _setLoading(true);
      _error = null;
      
      final user = _auth.currentUser;
      if (user == null) {
        _setLoading(false);
        return;
      }

      // Force refresh from database by fetching devices
      final snapshot = await _database
          .child('users')
          .child(user.uid)
          .child('devices')
          .get();

      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        _devices = [];
      } else {
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
                deviceId: deviceKey.toString(),
              ));
            });
          }

          devices.add(Device(
            id: deviceKey.toString(),
            appliances: appliances,
          ));
        });
        _devices = devices;
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to refresh data: $e';
      _setLoading(false);
      notifyListeners();
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  // ==============================
  // CHAT MESSAGE PERSISTENCE
  // ==============================

  /// Save a chat message to Firebase
  /// Messages are stored at: users/{uid}/chats/{messageId}
  Future<bool> saveChatMessage({
    required String userMessage,
    required String aiResponse,
    required DateTime timestamp,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final messageId = _database.child('users').child(user.uid).child('chats').push().key;
      if (messageId == null) return false;

      await _database
          .child('users')
          .child(user.uid)
          .child('chats')
          .child(messageId)
          .set({
        'userMessage': userMessage,
        'aiResponse': aiResponse,
        'timestamp': timestamp.millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      debugPrint('Error saving chat message: $e');
      return false;
    }
  }

  /// Retrieve chat history for current user
  /// Returns messages in reverse chronological order (newest first)
  Future<List<Map<String, dynamic>>> getChatHistory({int limit = 50}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _database
          .child('users')
          .child(user.uid)
          .child('chats')
          .orderByChild('timestamp')
          .limitToLast(limit)
          .get();

      if (!snapshot.exists) return [];

      final messages = <Map<String, dynamic>>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      // Convert to list and reverse to get newest first
      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          messages.add({
            'id': key,
            'userMessage': value['userMessage'] ?? '',
            'aiResponse': value['aiResponse'] ?? '',
            'timestamp': DateTime.fromMillisecondsSinceEpoch(
              (value['timestamp'] as int?) ?? 0,
            ),
          });
        }
      });

      // Sort by timestamp descending (newest first)
      messages.sort((a, b) => (b['timestamp'] as DateTime)
          .compareTo(a['timestamp'] as DateTime));

      return messages;
    } catch (e) {
      debugPrint('Error retrieving chat history: $e');
      return [];
    }
  }

  /// Delete a chat message by ID
  Future<bool> deleteChatMessage(String messageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _database
          .child('users')
          .child(user.uid)
          .child('chats')
          .child(messageId)
          .remove();

      return true;
    } catch (e) {
      debugPrint('Error deleting chat message: $e');
      return false;
    }
  }

  /// Clear all chat history for current user
  Future<bool> clearChatHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _database
          .child('users')
          .child(user.uid)
          .child('chats')
          .remove();

      return true;
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
      return false;
    }
  }
}