class Appliance {
  final String id;
  final String deviceId;
  final double current;
  final bool peak;
  final DateTime timestamp;

  Appliance({
    required this.id,
    required this.deviceId,
    required this.current,
    required this.peak,
    required this.timestamp,
  });

  factory Appliance.fromMap(Map<String, dynamic> map, String id, String deviceId) {
    return Appliance(
      id: id,
      deviceId: deviceId,
      current: (map['current'] ?? 0).toDouble(),
      peak: map['peak'] ?? false,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'current': current,
      'peak': peak,
      'timestamp': timestamp.millisecondsSinceEpoch,
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