import 'dart:async';

import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'local_notification_service.dart';
import '../models/appliance.dart';

/// Watches the Firebase realtime database for appliances whose current
/// exceeds their configured peak threshold.  When a violation is detected it
/// triggers a local notification.  The logic is kept entirely inside this
/// service so that later we can swap in FCM (or cloud functions) with a
/// minimal change.
///
/// The service also debounces notifications per appliance (60‑second cooldown)
/// to avoid spamming the user.
class PeakMonitorService {
  final FirebaseService _firebase;
  final LocalNotificationService _notifier;

  /// last time we issued an alert for each appliance id
  final Map<String, DateTime> _lastAlert = {};

  StreamSubscription? _deviceSub;

  PeakMonitorService(this._firebase, this._notifier);

  /// Start listening to the database.  This may be called multiple times but
  /// only a single subscription will be active at a time.
  void start() {
    debugPrint('PeakMonitorService starting');
    _notifier.init(); // ensure notifications ready

    _deviceSub?.cancel();
    _deviceSub = _firebase.getDevicesStream().listen(_onDevices);
  }

  void dispose() {
    _deviceSub?.cancel();
    _deviceSub = null;
  }

  void _onDevices(List<Device> devices) {
    final now = DateTime.now();
    debugPrint('PeakMonitorService received ${devices.length} devices');
    for (final device in devices) {
      for (final app in device.appliances) {
        final name = app.id;
        final current = app.live.current;
        final peak = app.config.peakCurrent;
        final enabled = app.config.enabled;

        debugPrint('Checking appliance $name: current=$current peak=$peak enabled=$enabled');

        if (!enabled) continue;
        if (current <= peak) continue;

        final last = _lastAlert[name];
        if (last != null && now.difference(last).inSeconds < 60) continue;

        // passed checks, fire notification
        debugPrint('Peak exceeded for $name, triggering alert');
        _lastAlert[name] = now;
        _notifier.triggerPeakAlert(name);
      }
    }
  }
}
