/// Model representing a remote install command from web or other devices
class InstallCommand {
  final String packageName;
  final String appName;
  final String timestamp;
  final String sourceDevice; // "web", "another-mobile", etc.
  final String? iconUrl;
  final String? versionName;

  const InstallCommand({
    required this.packageName,
    required this.appName,
    required this.timestamp,
    required this.sourceDevice,
    this.iconUrl,
    this.versionName,
  });

  /// Create from JSON
  factory InstallCommand.fromJson(Map<String, dynamic> json) {
    return InstallCommand(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      timestamp: json['timestamp'] as String,
      sourceDevice: json['sourceDevice'] as String,
      iconUrl: json['iconUrl'] as String?,
      versionName: json['versionName'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'timestamp': timestamp,
      'sourceDevice': sourceDevice,
      if (iconUrl != null) 'iconUrl': iconUrl,
      if (versionName != null) 'versionName': versionName,
    };
  }

  /// Get a unique identifier for this command
  String get id => '${packageName}_$timestamp';

  @override
  String toString() {
    return 'InstallCommand(packageName: $packageName, appName: $appName, '
        'sourceDevice: $sourceDevice, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InstallCommand &&
        other.packageName == packageName &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(packageName, timestamp);
}
