/// Represents a single appliance attached to a device in the
/// Energy Monitor application. Data is organised into three
/// sub‑nodes in Firebase Realtime Database: `config`, `live` and
/// `stats`.
///
/// The model keeps minimal top‑level fields (`id`, `name`,
/// optionally `deviceId`) and exposes helpers for the old flat
/// structure so existing widgets (e.g. `ApplianceCard`) continue
/// to work without modification.
class Appliance {
  // --- identifier information ---
  final String id; // same as the key in Firebase
  final String? deviceId; // parent device key, may be null
  final String name; // user-readable name (stored in config)

  // --- grouped data ---
  final ApplianceConfig config;
  final ApplianceLive live;
  final ApplianceStats stats;

  Appliance({
    required this.id,
    this.deviceId,
    required this.name,
    required this.config,
    required this.live,
    required this.stats,
  });

  /// Create an [Appliance] from a map obtained from Firebase.
  ///
  /// Handles both the new nested structure as well as the old
  /// flat layout for backwards compatibility. If a sub‑map is
  /// missing, default values are supplied so that widgets never
  /// crash when rendering.
  factory Appliance.fromMap(Map<String, dynamic>? map, String id,
      {String? deviceId}) {
    // defaults used when keys are missing or null
    double tryDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int tryInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    String tryString(dynamic v, [String def = '']) {
      if (v == null) return def;
      return v.toString();
    }

    map = map ?? <String, dynamic>{};

    // Extract config map or fall back to flat fields.
    final configMap = Map<String, dynamic>.from(
      map['config'] as Map<dynamic, dynamic>? ?? {},
    );

    final liveMap = Map<String, dynamic>.from(
      map['live'] as Map<dynamic, dynamic>? ?? {},
    );

    final statsMap = Map<String, dynamic>.from(
      map['stats'] as Map<dynamic, dynamic>? ?? {},
    );

    // backwards compatibility: flat values
    if (map.containsKey('current')) {
      liveMap['current'] = map['current'];
    }
    if (map.containsKey('power')) {
      liveMap['power'] = map['power'];
    }
    if (map.containsKey('timestamp')) {
      liveMap['timestamp'] = map['timestamp'];
    }
    // legacy flat 'status' removed — do not copy into liveMap
    if (map.containsKey('peak')) {
      // legacy peak flag: convert to peakCurrent threshold
      if (!configMap.containsKey('peakCurrent')) {
        configMap['peakCurrent'] = (map['peak'] == true) ? 1.0 : 0.0;
      }
    }

    final name = tryString(configMap['name'], id);

    return Appliance(
      id: id,
      deviceId: deviceId,
      name: name,
      config: ApplianceConfig(
        voltage: tryDouble(configMap['voltage'] ?? 230.0),
        calibration: tryDouble(configMap['calibration'] ?? 1.0),
        peakCurrent: tryDouble(configMap['peakCurrent']),
        gpioPin: tryInt(configMap['gpioPin']),
        enabled: (configMap['enabled'] ?? true) == true,
      ),
      live: ApplianceLive(
        current: tryDouble(liveMap['current']),
        power: tryDouble(liveMap['power']),
        timestamp: tryInt(liveMap['timestamp']),
      ),
      stats: ApplianceStats(
        todayEnergy: tryDouble(statsMap['todayEnergy']),
        monthEnergy: tryDouble(statsMap['monthEnergy']),
        lastCalcTime: tryInt(statsMap['lastCalcTime']),
      ),
    );
  }

  /// Converts this object back into a map suitable for writing
  /// to Firebase, nesting the values under `config`, `live` and
  /// `stats`.
  Map<String, dynamic> toMap() {
    return {
      'config': config.toMap(),
      'live': live.toMap(),
      'stats': stats.toMap(),
    };
  }

  // --- convenience getters for existing UI ---

  /// Current in amperes (from live data).
  double get current => live.current;

  /// Peak condition based on configured threshold.
  bool get peak => live.current >= config.peakCurrent;

  /// Timestamp converted to [DateTime].
  DateTime get timestamp =>
      DateTime.fromMillisecondsSinceEpoch(live.timestamp);
}

/// Configuration parameters for an appliance.
class ApplianceConfig {
  final double voltage;
  final double calibration;
  final double peakCurrent;
  final int gpioPin;
  final bool enabled;

  const ApplianceConfig({
    this.voltage = 230.0,
    this.calibration = 1.0,
    this.peakCurrent = 0.0,
    this.gpioPin = 0,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'voltage': voltage,
      'calibration': calibration,
      'peakCurrent': peakCurrent,
      'gpioPin': gpioPin,
      'enabled': enabled,
    };
  }
}

/// Live telemetry values for the appliance.
class ApplianceLive {
  final double current;
  final double power;
  final int timestamp;
  const ApplianceLive({
    this.current = 0.0,
    this.power = 0.0,
    this.timestamp = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'current': current,
      'power': power,
      'timestamp': timestamp,
    };
  }
}

/// Aggregated statistics for display or reporting.
class ApplianceStats {
  final double todayEnergy;
  final double monthEnergy;
  final int lastCalcTime;

  const ApplianceStats({
    this.todayEnergy = 0.0,
    this.monthEnergy = 0.0,
    this.lastCalcTime = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'todayEnergy': todayEnergy,
      'monthEnergy': monthEnergy,
      'lastCalcTime': lastCalcTime,
    };
  }
}

class Device {
  final String id;
  final List<Appliance> appliances;

  Device({
    required this.id,
    required this.appliances,
  });

  bool get hasPeakAppliances {
    return appliances.any((appliance) => appliance.peak);
  }

  List<Appliance> get sortedAppliances {
    final sorted = List<Appliance>.from(appliances);
    sorted.sort((a, b) => b.current.compareTo(a.current));
    return sorted;
  }
}