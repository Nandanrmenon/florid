import 'package:json_annotation/json_annotation.dart';

part 'fdroid_app.g.dart';

/// Represents a repository source for an app
class RepositorySource {
  final String name;
  final String url;

  const RepositorySource({
    required this.name,
    required this.url,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepositorySource &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          name == other.name;

  @override
  int get hashCode => Object.hash(url, name);
}

@JsonSerializable()
class FDroidApp {
  final String packageName;
  final String name;
  final String summary;
  final String description;
  final String? icon;
  final String? authorName;
  final String? authorEmail;
  final String? authorWebSite;
  final String? webSite;
  final String? issueTracker;
  final String? sourceCode;
  final String? changelog;
  final String? donate;
  final String? bitcoin;
  final String? flattrID;
  final String license;
  final List<String>? categories;
  final Map<String, FDroidVersion>? packages;
  final String? suggestedVersionName;
  final int? suggestedVersionCode;
  final DateTime? added;
  final DateTime? lastUpdated;
  @JsonKey(ignore: true)
  final String repositoryUrl;
  @JsonKey(ignore: true)
  final List<RepositorySource>? availableRepositories;

  const FDroidApp({
    required this.packageName,
    required this.name,
    required this.summary,
    required this.description,
    this.icon,
    this.authorName,
    this.authorEmail,
    this.authorWebSite,
    this.webSite,
    this.issueTracker,
    this.sourceCode,
    this.changelog,
    this.donate,
    this.bitcoin,
    this.flattrID,
    required this.license,
    this.categories,
    this.packages,
    this.suggestedVersionName,
    this.suggestedVersionCode,
    this.added,
    this.lastUpdated,
    this.repositoryUrl = 'https://f-droid.org/repo',
    this.availableRepositories,
  });

  factory FDroidApp.fromJson(Map<String, dynamic> json) =>
      _$FDroidAppFromJson(json);

  Map<String, dynamic> toJson() => _$FDroidAppToJson(this);

  String get iconUrl => icon != null
      ? '$repositoryUrl/icons-640/$icon'
      : '$repositoryUrl/icons-640/default.png';

  /// Returns a conservative list of candidate icon URLs.
  /// Tries only the most likely locations to minimize 404 errors.
  List<String> get iconUrls {
    final urls = <String>[];
    final seen = <String>{};

    void add(String url) {
      if (url.isEmpty || seen.contains(url)) return;
      seen.add(url);
      urls.add(url);
    }

    if (icon != null && icon!.isNotEmpty) {
      final iconPath = icon!;

      // Try the direct path as provided by the index (most likely to succeed)
      add('$repositoryUrl/$iconPath');

      // Try high-res version with the icon path
      add('$repositoryUrl/icons-640/$iconPath');

      // Try medium-res as fallback
      add('$repositoryUrl/icons-320/$iconPath');

      // Extract just the filename if path includes subdirectories
      final parts = iconPath.split('/');
      if (parts.length > 1) {
        final fileName = parts.last;
        // Try the filename in the package directory
        add('$repositoryUrl/${parts[0]}/$fileName');
      }
    }

    // Final fallback - reliable default icon
    add('https://f-droid.org/assets/fdroid-logo.png');

    return urls;
  }

  String get categoryString => categories?.join(', ') ?? 'Unknown';

  FDroidVersion? get latestVersion {
    if (packages == null || packages!.isEmpty) return null;
    final versions = packages!.values.toList();
    versions.sort((a, b) => b.versionCode.compareTo(a.versionCode));
    return versions.first;
  }

  /// Creates a copy of this app with a specific version set as the latest
  FDroidApp copyWithVersion(FDroidVersion version) {
    return FDroidApp(
      packageName: packageName,
      name: name,
      summary: summary,
      description: description,
      icon: icon,
      authorName: authorName,
      authorEmail: authorEmail,
      authorWebSite: authorWebSite,
      webSite: webSite,
      issueTracker: issueTracker,
      sourceCode: sourceCode,
      changelog: changelog,
      donate: donate,
      bitcoin: bitcoin,
      flattrID: flattrID,
      license: license,
      categories: categories,
      packages: {version.versionCode.toString(): version},
      suggestedVersionName: suggestedVersionName,
      suggestedVersionCode: suggestedVersionCode,
      added: added,
      lastUpdated: lastUpdated,
      repositoryUrl: repositoryUrl,
      availableRepositories: availableRepositories,
    );
  }

  FDroidApp copyWith({
    String? packageName,
    String? name,
    String? summary,
    String? description,
    String? icon,
    String? authorName,
    String? authorEmail,
    String? authorWebSite,
    String? webSite,
    String? issueTracker,
    String? sourceCode,
    String? changelog,
    String? donate,
    String? bitcoin,
    String? flattrID,
    String? license,
    List<String>? categories,
    Map<String, FDroidVersion>? packages,
    String? suggestedVersionName,
    int? suggestedVersionCode,
    DateTime? added,
    DateTime? lastUpdated,
    String? repositoryUrl,
    List<RepositorySource>? availableRepositories,
  }) {
    return FDroidApp(
      packageName: packageName ?? this.packageName,
      name: name ?? this.name,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      authorWebSite: authorWebSite ?? this.authorWebSite,
      webSite: webSite ?? this.webSite,
      issueTracker: issueTracker ?? this.issueTracker,
      sourceCode: sourceCode ?? this.sourceCode,
      changelog: changelog ?? this.changelog,
      donate: donate ?? this.donate,
      bitcoin: bitcoin ?? this.bitcoin,
      flattrID: flattrID ?? this.flattrID,
      license: license ?? this.license,
      categories: categories ?? this.categories,
      packages: packages ?? this.packages,
      suggestedVersionName: suggestedVersionName ?? this.suggestedVersionName,
      suggestedVersionCode: suggestedVersionCode ?? this.suggestedVersionCode,
      added: added ?? this.added,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      repositoryUrl: repositoryUrl ?? this.repositoryUrl,
      availableRepositories: availableRepositories ?? this.availableRepositories,
    );
  }
}

@JsonSerializable()
class FDroidVersion {
  final int versionCode;
  final String versionName;
  final int size;
  final String? minSdkVersion;
  final String? targetSdkVersion;
  final String? maxSdkVersion;
  final DateTime added;
  final String apkName;
  final String hash;
  final String hashType;
  final String? sig;
  final List<String>? permissions;
  final List<String>? features;
  final List<String>? nativecode;
  final String? whatsNew;

  const FDroidVersion({
    required this.versionCode,
    required this.versionName,
    required this.size,
    this.minSdkVersion,
    this.targetSdkVersion,
    this.maxSdkVersion,
    required this.added,
    required this.apkName,
    required this.hash,
    required this.hashType,
    this.sig,
    this.permissions,
    this.features,
    this.nativecode,
    this.whatsNew,
  });

  factory FDroidVersion.fromJson(Map<String, dynamic> json) =>
      _$FDroidVersionFromJson(json);

  Map<String, dynamic> toJson() => _$FDroidVersionToJson(this);

  String downloadUrl(String repositoryUrl) => '$repositoryUrl/$apkName';

  String get sizeString {
    if (size <= 0) return 'Unknown';
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

@JsonSerializable()
class FDroidCategory {
  final String id;
  final String name;
  final String description;
  final int appCount;
  const FDroidCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.appCount,
  });

  factory FDroidCategory.fromJson(Map<String, dynamic> json) =>
      _$FDroidCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$FDroidCategoryToJson(this);
}

class FDroidRepository {
  final String name;
  final String description;
  final String icon;
  final String timestamp; // raw timestamp string/number converted to string
  final String version;
  final int maxage;
  final Map<String, FDroidApp> apps; // keyed by package name

  const FDroidRepository({
    required this.name,
    required this.description,
    required this.icon,
    required this.timestamp,
    required this.version,
    required this.maxage,
    required this.apps,
  });

  /// Custom parser for F-Droid index-v2.json structure.
  /// The official schema (simplified) is:
  /// {
  ///   "repo": { "name": ..., "description": ..., "icon": ..., "timestamp": <epoch>, "version": ..., "maxage": ... },
  ///   "packages": {
  ///       "org.example.app": {
  ///          "metadata": { ... app fields ... },
  ///          "versions": { "100": { ... version fields ... }, ... }
  ///       },
  ///       ...
  ///   }
  /// }
  factory FDroidRepository.fromJson(
    Map<String, dynamic> json, {
    String? repositoryUrl,
  }) {
    final repoMeta =
        (json['repo'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final packages =
        (json['packages'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    // Use provided URL or default to official F-Droid
    final baseUrl = repositoryUrl ?? 'https://f-droid.org/repo';

    DateTime parseEpochOrIso(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      if (v is int) {
        // F-Droid uses seconds since epoch
        if (v.toString().length <= 10) {
          return DateTime.fromMillisecondsSinceEpoch(v * 1000, isUtc: true);
        }
        return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
      }
      if (v is String) {
        // Try int first
        final asInt = int.tryParse(v);
        if (asInt != null) {
          return DateTime.fromMillisecondsSinceEpoch(
            (asInt.toString().length <= 10 ? asInt * 1000 : asInt),
            isUtc: true,
          );
        }
        return DateTime.tryParse(v) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      }
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    final Map<String, FDroidApp> apps = {};

    packages.forEach((pkgName, pkgData) {
      try {
        final pkgMap = (pkgData as Map).cast<String, dynamic>();
        final metadata =
            (pkgMap['metadata'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        final versionsMap =
            (pkgMap['versions'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

        // Helper to extract a localized string: metadata fields sometimes
        // appear as {'en-US': 'Value', 'de-DE': 'Wert'} instead of a plain String.
        String extractLocalized(dynamic raw, {String? fallbackKey}) {
          if (raw == null) return '';
          // Plain string
          if (raw is String) return raw;
          if (raw is Map) {
            // Try exact fallback key first
            if (fallbackKey != null && raw[fallbackKey] is String) {
              return raw[fallbackKey] as String;
            }
            // Try common English keys
            const englishPrefs = ['en-US', 'en', 'en_GB'];
            for (final key in englishPrefs) {
              if (raw[key] is String) return raw[key] as String;
            }
            // Otherwise first string value
            for (final value in raw.values) {
              if (value is String) return value;
            }
          }
          return raw.toString();
        }

        final Map<String, FDroidVersion> versionObjs = {};
        versionsMap.forEach((vCodeKey, vData) {
          try {
            final versionData = (vData as Map).cast<String, dynamic>();

            final manifest =
                (versionData['manifest'] as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{};
            final usesSdk =
                (manifest['usesSdk'] as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{};
            final fileMap = (versionData['file'] as Map?)
                ?.cast<String, dynamic>();

            int versionCode =
                int.tryParse(vCodeKey.toString()) ??
                int.tryParse(versionData['versionCode']?.toString() ?? '') ??
                (manifest['versionCode'] as int? ?? 0);

            String versionName =
                (versionData['versionName'] ??
                        manifest['versionName'] ??
                        versionData['name'] ??
                        versionCode.toString())
                    .toString();

            int size = 0;
            final rawSize = versionData['size'] ?? fileMap?['size'];
            if (rawSize is int) {
              size = rawSize;
            } else if (rawSize is String) {
              size = int.tryParse(rawSize) ?? 0;
            }

            final added = parseEpochOrIso(
              versionData['timestamp'] ?? versionData['added'],
            );

            String apkName =
                (versionData['apkName'] ??
                        (versionData['file'] is String
                            ? versionData['file']
                            : fileMap?['name']) ??
                        versionData['apk'] ??
                        '')
                    .toString();
            while (apkName.startsWith('/')) {
              apkName = apkName.substring(1);
            }

            String hash =
                (versionData['hash'] ??
                        versionData['sha256'] ??
                        versionData['sha256sum'] ??
                        fileMap?['sha256'] ??
                        '')
                    .toString();
            String hashType =
                (versionData['hashType'] ??
                        (versionData['sha256'] != null ||
                                versionData['sha256sum'] != null ||
                                fileMap?['sha256'] != null
                            ? 'sha256'
                            : 'unknown'))
                    .toString();

            List<String>? permissions = (versionData['permissions'] as List?)
                ?.map((e) => e.toString())
                .toList();
            permissions ??= (manifest['usesPermission'] as List?)
                ?.map(
                  (e) => e is Map && e['name'] != null
                      ? e['name'].toString()
                      : e.toString(),
                )
                .toList();

            List<String>? features = (versionData['features'] as List?)
                ?.map((e) => e.toString())
                .toList();
            features ??= (manifest['usesFeature'] as List?)
                ?.map(
                  (e) => e is Map && e['name'] != null
                      ? e['name'].toString()
                      : e.toString(),
                )
                .toList();

            List<String>? nativecode = (versionData['nativecode'] as List?)
                ?.map((e) => e.toString())
                .toList();
            nativecode ??= (manifest['nativecode'] as List?)
                ?.map((e) => e.toString())
                .toList();

            final minSdkVersion = usesSdk['minSdkVersion']?.toString();
            final targetSdkVersion = usesSdk['targetSdkVersion']?.toString();
            final maxSdkVersion = usesSdk['maxSdkVersion']?.toString();

            // Extract localized what's new/release notes from version
            String? whatsNew;
            final rawWhatsNew = versionData['whatsNew'];
            if (rawWhatsNew != null) {
              if (rawWhatsNew is String) {
                final normalized = rawWhatsNew.trim();
                whatsNew = normalized.isEmpty ? null : normalized;
              } else {
                // Some repos may localize this field
                final localized = extractLocalized(rawWhatsNew);
                final normalized = localized.trim();
                whatsNew = normalized.isEmpty ? null : normalized;
              }
            }

            if (apkName.isEmpty) {
              // Skip invalid version entries without an APK reference
              return;
            }

            versionObjs[versionCode.toString()] = FDroidVersion(
              versionCode: versionCode,
              versionName: versionName,
              size: size,
              added: added,
              apkName: apkName,
              hash: hash,
              hashType: hashType,
              permissions: permissions,
              features: features,
              nativecode: nativecode,
              minSdkVersion: minSdkVersion,
              targetSdkVersion: targetSdkVersion,
              maxSdkVersion: maxSdkVersion,
              whatsNew: whatsNew,
            );
          } catch (_) {
            // Silently skip malformed version; could add logging hook
          }
        });

        DateTime? added;
        DateTime? lastUpdated;
        final addedRaw = metadata['added'] ?? metadata['firstAdded'];
        final updatedRaw =
            metadata['lastUpdated'] ??
            metadata['updated'] ??
            metadata['modified'];
        if (addedRaw != null) added = parseEpochOrIso(addedRaw);
        if (updatedRaw != null) lastUpdated = parseEpochOrIso(updatedRaw);

        // Icon field in index-v2 can itself be localized or a structured map:
        // e.g., {"en-US": {"name": "/com.foo/icon_x.png", "size":123, "sha256":"..."}}
        String normalizeIconPath(String raw) {
          var trimmed = raw.trim();
          if (trimmed.isEmpty) return trimmed;
          while (trimmed.startsWith('/')) {
            trimmed = trimmed.substring(1);
          }
          if (trimmed.contains('{')) return '';
          // If path contains directories, keep them (repo may store hashed under dirs), but
          // we still allow filename-only variants later.
          return trimmed;
        }

        String? extractIcon(dynamic raw) {
          if (raw == null) return null;
          if (raw is String) return normalizeIconPath(raw);
          if (raw is Map) {
            // Try English locales first
            const englishPrefs = ['en-US', 'en', 'en_GB'];
            for (final key in englishPrefs) {
              final val = raw[key];
              if (val is String) return normalizeIconPath(val);
              if (val is Map && val['name'] is String) {
                return normalizeIconPath(val['name'] as String);
              }
            }
            // Fallback: search any nested map with a 'name'
            for (final v in raw.values) {
              if (v is Map && v['name'] is String) {
                return normalizeIconPath(v['name'] as String);
              }
              if (v is String) return normalizeIconPath(v);
            }
          }
          return null;
        }

        final app = FDroidApp(
          packageName: pkgName,
          name: extractLocalized(
            metadata['name'] ?? metadata['appName'] ?? pkgName,
          ),
          // Some entries have very sparse metadata; provide safe fallbacks
          summary: extractLocalized(
            metadata['summary'] ?? metadata['shortDescription'],
          ),
          description: extractLocalized(
            metadata['description'] ??
                metadata['longDescription'] ??
                metadata['summary'],
          ),
          icon: extractIcon(metadata['icon']),
          authorName: metadata['authorName']?.toString(),
          authorEmail: metadata['authorEmail']?.toString(),
          authorWebSite: metadata['authorWebSite']?.toString(),
          webSite: metadata['webSite']?.toString(),
          issueTracker: metadata['issueTracker']?.toString(),
          sourceCode: metadata['sourceCode']?.toString(),
          changelog: metadata['changelog']?.toString(),
          donate: metadata['donate']?.toString(),
          bitcoin: metadata['bitcoin']?.toString(),
          flattrID: metadata['flattrID']?.toString(),
          license: (metadata['license'] ?? 'Unknown').toString(),
          categories: (metadata['categories'] as List?)
              ?.map((e) => e.toString())
              .toList(),
          packages: versionObjs.isEmpty
              ? null
              : versionObjs.map((k, v) => MapEntry(k, v)),
          suggestedVersionName: metadata['suggestedVersionName']?.toString(),
          suggestedVersionCode: metadata['suggestedVersionCode'] is int
              ? metadata['suggestedVersionCode'] as int
              : int.tryParse(
                  metadata['suggestedVersionCode']?.toString() ?? '',
                ),
          added: added,
          lastUpdated: lastUpdated,
          repositoryUrl: baseUrl,
        );

        apps[pkgName] = app;
      } catch (_) {
        // Skip whole package if malformed
      }
    });

    return FDroidRepository(
      name: (repoMeta['name'] ?? 'F-Droid').toString(),
      description: (repoMeta['description'] ?? '').toString(),
      icon: (repoMeta['icon'] ?? '').toString(),
      timestamp: (repoMeta['timestamp'] ?? repoMeta['lastUpdated'] ?? '')
          .toString(),
      version: (repoMeta['version'] ?? '').toString(),
      maxage: repoMeta['maxage'] is int
          ? repoMeta['maxage'] as int
          : int.tryParse(repoMeta['maxage']?.toString() ?? '0') ?? 0,
      apps: apps,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'icon': icon,
    'timestamp': timestamp,
    'version': version,
    'maxage': maxage,
    'apps': apps.map((k, v) => MapEntry(k, v.toJson())),
  };

  List<FDroidApp> get appsList => apps.values.toList();

  List<FDroidApp> get latestApps {
    final sortedApps = appsList.where((app) => app.added != null).toList();
    sortedApps.sort((a, b) => b.added!.compareTo(a.added!));
    return sortedApps.take(50).toList();
  }

  List<String> get categories {
    final categorySet = <String>{};
    for (final app in appsList) {
      if (app.categories != null) {
        categorySet.addAll(app.categories!);
      }
    }
    final categories = categorySet.toList();
    categories.sort();
    return categories;
  }

  List<FDroidApp> getAppsByCategory(String category) {
    return appsList
        .where((app) => app.categories?.contains(category) ?? false)
        .toList();
  }

  List<FDroidApp> searchApps(String query) {
    final lowerQuery = query.toLowerCase();

    // Create scored results
    final scoredResults = <({FDroidApp app, int score})>[];

    for (final app in appsList) {
      int score = 0;
      final name = app.name.toLowerCase();
      final summary = app.summary.toLowerCase();
      final description = app.description.toLowerCase();
      final packageName = app.packageName.toLowerCase();
      final categories =
          app.categories?.map((c) => c.toLowerCase()).toList() ?? [];

      // Exact name match gets highest priority
      if (name == lowerQuery) {
        score = 10000;
      }
      // Name starts with query
      else if (name.startsWith(lowerQuery)) {
        score = 5000;
      }
      // Name contains query
      else if (name.contains(lowerQuery)) {
        score = 1000;
      }
      // Summary contains query
      else if (summary.contains(lowerQuery)) {
        score = 100;
      }
      // Description contains query
      else if (description.contains(lowerQuery)) {
        score = 50;
      }
      // Category contains query
      else if (categories.any((cat) => cat.contains(lowerQuery))) {
        score = 25;
      }
      // Package name contains query
      else if (packageName.contains(lowerQuery)) {
        score = 10;
      }

      if (score > 0) {
        scoredResults.add((app: app, score: score));
      }
    }

    // Sort by score (descending), then by name (ascending)
    scoredResults.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.app.name.toLowerCase().compareTo(b.app.name.toLowerCase());
    });

    return scoredResults.map((result) => result.app).toList();
  }
}
