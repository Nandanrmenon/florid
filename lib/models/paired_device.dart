/// Model representing a paired device for web sync
class PairedDevice {
  final String deviceId;
  final String deviceName;
  final DateTime pairedAt;
  final bool isActive;
  final String? lastSeen;

  const PairedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.pairedAt,
    required this.isActive,
    this.lastSeen,
  });

  /// Create from JSON
  factory PairedDevice.fromJson(Map<String, dynamic> json) {
    return PairedDevice(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      pairedAt: DateTime.parse(json['pairedAt'] as String),
      isActive: json['isActive'] as bool? ?? false,
      lastSeen: json['lastSeen'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'pairedAt': pairedAt.toIso8601String(),
      'isActive': isActive,
      if (lastSeen != null) 'lastSeen': lastSeen,
    };
  }

  /// Create a copy with updated fields
  PairedDevice copyWith({
    String? deviceId,
    String? deviceName,
    DateTime? pairedAt,
    bool? isActive,
    String? lastSeen,
  }) {
    return PairedDevice(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      pairedAt: pairedAt ?? this.pairedAt,
      isActive: isActive ?? this.isActive,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  String toString() {
    return 'PairedDevice(deviceId: $deviceId, deviceName: $deviceName, '
        'pairedAt: $pairedAt, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PairedDevice && other.deviceId == deviceId;
  }

  @override
  int get hashCode => deviceId.hashCode;
}
