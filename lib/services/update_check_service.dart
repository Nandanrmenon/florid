import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../l10n/current_l10n.dart';
import '../models/fdroid_app.dart';
import '../providers/settings_provider.dart';
import '../services/app_preferences_service.dart';
import '../services/database_service.dart';
import '../services/fdroid_api_service.dart';

const String _updateCheckTask = 'florid_update_check';
const String _updateCheckTaskName = 'updateCheckTask';
const String _updateCheckDebugTask = 'florid_update_check_debug';
const String _updateCheckDebugTaskName = 'updateCheckDebugTask';
const String _updateNotificationSignatureKey =
    'background_update_notification_signature';
const String _updateNotificationTimestampKey =
    'background_update_notification_timestamp';
const Duration _updateNotificationMinInterval = Duration(hours: 24);

class UpdateCheckService {
  static const String updatesChannelId = 'com.florid.updates';

  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    await scheduleFromPrefs();
  }

  static Future<void> scheduleFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled =
        prefs.getBool(SettingsProvider.backgroundUpdatesKey) ?? true;
    final intervalHours =
        prefs.getInt(SettingsProvider.updateIntervalHoursKey) ?? 6;
    final policyIndex =
        prefs.getInt(SettingsProvider.updateNetworkPolicyKey) ??
        UpdateNetworkPolicy.any.index;
    final policy =
        policyIndex >= 0 && policyIndex < UpdateNetworkPolicy.values.length
        ? UpdateNetworkPolicy.values[policyIndex]
        : UpdateNetworkPolicy.any;

    if (!enabled) {
      await Workmanager().cancelByUniqueName(_updateCheckTask);
      return;
    }

    final constraints = Constraints(
      networkType: _networkTypeForPolicy(policy),
      requiresCharging: policy == UpdateNetworkPolicy.wifiAndCharging,
    );

    final safeIntervalHours = intervalHours < 1 ? 1 : intervalHours;

    await Workmanager().registerPeriodicTask(
      _updateCheckTask,
      _updateCheckTaskName,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      frequency: Duration(hours: safeIntervalHours),
      constraints: constraints,
    );
  }

  static Future<void> scheduleDebugOnce({
    Duration delay = const Duration(seconds: 10),
  }) async {
    await Workmanager().registerOneOffTask(
      _updateCheckDebugTask,
      _updateCheckDebugTaskName,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      initialDelay: delay,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  static Future<void> runDebugInApp({
    Duration delay = const Duration(seconds: 10),
  }) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    try {
      await _runUpdateCheck(debug: true);
    } catch (e) {
      debugPrint('Debug update check failed: $e');
    }
  }

  static Future<void> showDebugNotificationNow(String message) async {
    try {
      await _showDebugNotification(message);
    } catch (e) {
      debugPrint('Debug notification failed: $e');
    }
  }

  static NetworkType _networkTypeForPolicy(UpdateNetworkPolicy policy) {
    switch (policy) {
      case UpdateNetworkPolicy.wifiOnly:
      case UpdateNetworkPolicy.wifiAndCharging:
        return NetworkType.unmetered;
      case UpdateNetworkPolicy.any:
      default:
        return NetworkType.connected;
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    if (taskName != _updateCheckTaskName &&
        taskName != _updateCheckDebugTaskName) {
      return Future.value(true);
    }

    try {
      final isDebug = taskName == _updateCheckDebugTaskName;
      await _runUpdateCheck(debug: isDebug);
    } catch (e) {
      debugPrint('Update check failed: $e');
    }

    return Future.value(true);
  });
}

Future<void> _runUpdateCheck({bool debug = false}) async {
  final prefs = await SharedPreferences.getInstance();
  final enabled = prefs.getBool(SettingsProvider.backgroundUpdatesKey) ?? true;
  if (!enabled && !debug) return;

  final db = DatabaseService();
  final repoMaps = await db.getAllRepositories();
  final enabledRepos = repoMaps
      .where((repo) => (repo['is_enabled'] as int? ?? 1) == 1)
      .toList();

  final repoUrls = enabledRepos.isNotEmpty
      ? enabledRepos.map((repo) => repo['url'] as String).toList()
      : <String>['https://f-droid.org/repo'];

  final api = FDroidApiService();
  final repositories = <FDroidRepository>[];
  for (final url in repoUrls) {
    try {
      repositories.add(await api.fetchRepositoryFromUrl(url));
    } catch (e) {
      debugPrint('Background repo fetch failed for $url: $e');
    }
  }

  if (repositories.isEmpty) {
    final cachedRepo = await _loadRepositoryFromDatabase(db);
    if (cachedRepo != null) {
      repositories.add(cachedRepo);
      if (debug) {
        await _showDebugNotification('Using cached repository data');
      }
    } else {
      if (debug) {
        await _showDebugNotification('No cached repository data');
      }
      return;
    }
  }

  final merged = _mergeRepositories(repositories);
  final installedApps = await InstalledApps.getInstalledApps();
  final appPrefs = AppPreferencesService();

  final updates = <FDroidApp>[];
  final updateVersions = <String, int>{};
  for (final installed in installedApps) {
    final fdroidApp = merged.apps[installed.packageName];
    if (fdroidApp == null) continue;

    final ignoreUpdates = await appPrefs.getIgnoreUpdates(
      installed.packageName,
    );
    if (ignoreUpdates) continue;

    final includeUnstable = await appPrefs.getIncludeUnstable(
      installed.packageName,
    );
    final latest = fdroidApp.getLatestVersion(includeUnstable: includeUnstable);
    if (latest == null) continue;

    final installedVersionCode = installed.versionCode;
    final installedVersionName = installed.versionName;
    final installedSha256 =
        null; // Note: Will be populated if available from database

    // Use helper to determine if this is a real update or just a rebuild
    final isRealUpdate = _isRealVersionUpdate(
      installedVersionCode: installedVersionCode,
      installedVersionName: installedVersionName,
      installedSha256: installedSha256,
      latestVersionCode: latest.versionCode,
      latestVersionName: latest.versionName,
      latestSha256: latest.hash,
    );

    if (isRealUpdate) {
      updates.add(fdroidApp);
      updateVersions[fdroidApp.packageName] = latest.versionCode;
    } else if (debug &&
        installedVersionName == latest.versionName &&
        installedVersionCode != latest.versionCode) {
      debugPrint(
        'Skipped rebuild notification: ${installed.packageName} '
        '$installedVersionName (code: $installedVersionCode -> ${latest.versionCode})',
      );
    }
  }

  if (updates.isEmpty) {
    if (debug) {
      await _showDebugNotification('No updates found');
    }
    return;
  }

  final signature = _buildUpdateSignature(updateVersions);
  final shouldNotify = await _shouldNotifyUpdates(signature, debug: debug);
  if (!shouldNotify) {
    return;
  }

  await _showUpdateNotification(updates);
  await _recordUpdateNotification(signature);

  if (debug) {
    await _showDebugNotification('Found ${updates.length} update(s)');
  }
}

String _buildUpdateSignature(Map<String, int> versions) {
  final entries = versions.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((entry) => '${entry.key}:${entry.value}').join('|');
}

Future<bool> _shouldNotifyUpdates(
  String signature, {
  bool debug = false,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final lastSignature = prefs.getString(_updateNotificationSignatureKey);
  final lastTimestamp = prefs.getInt(_updateNotificationTimestampKey);
  if (lastSignature != signature) {
    return true;
  }

  if (lastTimestamp == null) {
    return true;
  }

  final lastTime = DateTime.fromMillisecondsSinceEpoch(lastTimestamp);
  final tooSoon =
      DateTime.now().difference(lastTime) < _updateNotificationMinInterval;
  if (tooSoon && debug) {
    await _showDebugNotification('Updates unchanged; notification suppressed');
  }

  return !tooSoon;
}

/// Checks if an update is a real version change or just a rebuild
/// Returns false if:
/// - SHA256 hash matches (same exact build)
/// - versionName is identical (indicates rebuild, not update)
/// - versionCode matches (already installed)
bool _isRealVersionUpdate({
  required int? installedVersionCode,
  required String? installedVersionName,
  required String? installedSha256,
  required int latestVersionCode,
  required String latestVersionName,
  required String latestSha256,
}) {
  // No version info available, assume it's an update
  if (installedVersionCode == null || installedVersionName == null) {
    return true;
  }

  // If SHA256 hashes match, it's the exact same build - no update needed
  if (installedSha256 != null &&
      installedSha256.isNotEmpty &&
      installedSha256 == latestSha256) {
    return false;
  }

  // Same version code = exact same build, no update
  if (installedVersionCode == latestVersionCode) {
    return false;
  }

  // Same version name but different code = rebuild of same version
  // This is not a real update (fixes the false positive issue)
  if (installedVersionName == latestVersionName) {
    return false;
  }

  // Different version name or code = real update
  return latestVersionCode > installedVersionCode;
}

Future<void> _recordUpdateNotification(String signature) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_updateNotificationSignatureKey, signature);
  await prefs.setInt(
    _updateNotificationTimestampKey,
    DateTime.now().millisecondsSinceEpoch,
  );
}

Future<void> _showDebugNotification(String message) async {
  final plugin = await _initNotifications();

  final l10n = currentL10n();
  final AndroidNotificationChannel channel = AndroidNotificationChannel(
    UpdateCheckService.updatesChannelId,
    l10n.updates_channel_name,
    description: l10n.updates_channel_description,
    importance: Importance.defaultImportance,
  );

  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      UpdateCheckService.updatesChannelId,
      l10n.updates_channel_name,
      channelDescription: l10n.updates_channel_description,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  await plugin.show(
    id: 2002,
    title: l10n.debug_update_check,
    body: message,
    notificationDetails: details,
    payload: jsonEncode({'type': 'debug_update_check', 'message': message}),
  );
}

FDroidRepository _mergeRepositories(List<FDroidRepository> repos) {
  final mergedApps = <String, FDroidApp>{};

  for (final repo in repos) {
    for (final entry in repo.apps.entries) {
      final packageName = entry.key;
      final app = entry.value;

      if (mergedApps.containsKey(packageName)) {
        final existing = mergedApps[packageName]!;
        final repoSource = RepositorySource(
          name: repo.name,
          url: app.repositoryUrl,
        );
        final availableRepos = existing.availableRepositories ?? [];
        if (!availableRepos.contains(repoSource)) {
          final updatedRepos = [...availableRepos, repoSource];
          mergedApps[packageName] = existing.copyWith(
            availableRepositories: updatedRepos,
          );
        }
      } else {
        mergedApps[packageName] = app.copyWith(
          availableRepositories: [
            RepositorySource(name: repo.name, url: app.repositoryUrl),
          ],
        );
      }
    }
  }

  return FDroidRepository(
    name: 'Merged Repositories',
    description: 'Merged from ${repos.length} repositories',
    icon: repos.first.icon,
    timestamp: repos.first.timestamp,
    version: repos.first.version,
    maxage: repos.first.maxage,
    apps: mergedApps,
  );
}

Future<FDroidRepository?> _loadRepositoryFromDatabase(
  DatabaseService db,
) async {
  try {
    final apps = await db.getAllApps();
    if (apps.isEmpty) return null;
    final repoName = await db.getMetadata('repo_name') ?? 'F-Droid';
    final repoDescription = await db.getMetadata('repo_description') ?? '';
    final appsMap = <String, FDroidApp>{};
    for (final app in apps) {
      appsMap[app.packageName] = app;
    }
    return FDroidRepository(
      name: repoName,
      description: repoDescription,
      icon: '',
      timestamp: '',
      version: '',
      maxage: 0,
      apps: appsMap,
    );
  } catch (e) {
    debugPrint('Failed to load cached repository: $e');
    return null;
  }
}

Future<void> _showUpdateNotification(List<FDroidApp> apps) async {
  final plugin = await _initNotifications();

  final l10n = currentL10n();
  final AndroidNotificationChannel channel = AndroidNotificationChannel(
    UpdateCheckService.updatesChannelId,
    l10n.updates_channel_name,
    description: l10n.updates_channel_description,
    importance: Importance.defaultImportance,
  );

  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  final count = apps.length;
  final names = apps.take(3).map((app) => app.name).join(', ');
  final summary = count <= 3
      ? names
      : l10n.and_n_more(names, count - 3);

  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      UpdateCheckService.updatesChannelId,
      l10n.updates_channel_name,
      channelDescription: l10n.updates_channel_description,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(summary),
    ),
  );

  await plugin.show(
    id: 2001,
    title: l10n.updates_available_title(count),
    body: summary,
    notificationDetails: details,
    payload: jsonEncode({'type': 'updates', 'count': count}),
  );
}

Future<FlutterLocalNotificationsPlugin> _initNotifications() async {
  final plugin = FlutterLocalNotificationsPlugin();

  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('ic_notification'),
  );

  const fallbackSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );

  try {
    await plugin.initialize(settings: initSettings);
  } on PlatformException catch (e) {
    if (e.code == 'invalid_icon') {
      debugPrint(
        'UpdateCheckService: ic_notification missing, using launcher icon',
      );
      await plugin.initialize(settings: fallbackSettings);
    } else {
      rethrow;
    }
  }

  return plugin;
}
