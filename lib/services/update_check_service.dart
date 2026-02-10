import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../models/fdroid_app.dart';
import '../providers/settings_provider.dart';
import '../services/app_preferences_service.dart';
import '../services/database_service.dart';
import '../services/fdroid_api_service.dart';

const String _updateCheckTask = 'florid_update_check';
const String _updateCheckTaskName = 'updateCheckTask';
const String _updateCheckDebugTask = 'florid_update_check_debug';
const String _updateCheckDebugTaskName = 'updateCheckDebugTask';

class UpdateCheckService {
  static const String updatesChannelId = 'com.florid.updates';
  static const String updatesChannelName = 'App Updates';

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
      existingWorkPolicy: ExistingWorkPolicy.replace,
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
  for (final installed in installedApps) {
    final fdroidApp = merged.apps[installed.packageName];
    if (fdroidApp == null) continue;

    final includeUnstable = await appPrefs.getIncludeUnstable(
      installed.packageName,
    );
    final latest = fdroidApp.getLatestVersion(includeUnstable: includeUnstable);
    if (latest == null) continue;

    final installedVersionCode = installed.versionCode;

    if (latest.versionCode > installedVersionCode) {
      updates.add(fdroidApp);
    }
  }

  if (updates.isEmpty) {
    if (debug) {
      await _showDebugNotification('No updates found');
    }
    return;
  }

  await _showUpdateNotification(updates);

  if (debug) {
    await _showDebugNotification('Found ${updates.length} update(s)');
  }
}

Future<void> _showDebugNotification(String message) async {
  final plugin = await _initNotifications();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    UpdateCheckService.updatesChannelId,
    UpdateCheckService.updatesChannelName,
    description: 'App update notifications',
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
      UpdateCheckService.updatesChannelName,
      channelDescription: 'App update notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  await plugin.show(
    2002,
    'Debug update check',
    message,
    details,
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

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    UpdateCheckService.updatesChannelId,
    UpdateCheckService.updatesChannelName,
    description: 'App update notifications',
    importance: Importance.defaultImportance,
  );

  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  final count = apps.length;
  final names = apps.take(3).map((app) => app.name).join(', ');
  final summary = count <= 3 ? names : '$names and ${count - 3} more';

  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      UpdateCheckService.updatesChannelId,
      UpdateCheckService.updatesChannelName,
      channelDescription: 'App update notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(summary),
    ),
  );

  await plugin.show(
    2001,
    'Updates available ($count)',
    summary,
    details,
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
    await plugin.initialize(initSettings);
  } on PlatformException catch (e) {
    if (e.code == 'invalid_icon') {
      debugPrint(
        'UpdateCheckService: ic_notification missing, using launcher icon',
      );
      await plugin.initialize(fallbackSettings);
    } else {
      rethrow;
    }
  }

  return plugin;
}
