import 'package:json_annotation/json_annotation.dart';

part 'fdroid_app.g.dart';

/// Represents a repository source for an app
class RepositorySource {
  final String name;
  final String url;

  const RepositorySource({required this.name, required this.url});

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
  final List<String>? antiFeatures;
  final Map<String, FDroidVersion>? packages;
  final String? suggestedVersionName;
  final int? suggestedVersionCode;
  final DateTime? added;
  final DateTime? lastUpdated;
  final String? featureGraphic;
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
    this.antiFeatures,
    this.packages,
    this.suggestedVersionName,
    this.suggestedVersionCode,
    this.added,
    this.lastUpdated,
    this.featureGraphic,
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
      final iconPath = icon!.trim();

      if (iconPath.startsWith('http://') || iconPath.startsWith('https://')) {
        // Absolute URL from repository metadata.
        add(iconPath);
      } else {
        final normalizedPath = iconPath.startsWith('/')
            ? iconPath.substring(1)
            : iconPath;

        // Always try exact repository-relative path first.
        add('$repositoryUrl/$normalizedPath');

        // Only try icon size directories when metadata gave a filename.
        // Paths containing '/' are usually already fully qualified.
        if (!normalizedPath.contains('/')) {
          add('$repositoryUrl/icons-640/$normalizedPath');
          add('$repositoryUrl/icons-320/$normalizedPath');
          add('$repositoryUrl/icons/$normalizedPath');
        }
      }
    }

    // Final fallback - reliable default icon
    add('https://f-droid.org/assets/fdroid-logo.png');

    return urls;
  }

  String get categoryString => categories?.join(', ') ?? 'Unknown';

  FDroidVersion? get latestVersion {
    return getLatestVersion();
  }

  /// Gets the latest version, optionally filtering out unstable versions
  FDroidVersion? getLatestVersion({bool includeUnstable = true}) {
    if (packages == null || packages!.isEmpty) return null;

    var versions = packages!.values.toList();

    // Filter out unstable versions if requested
    if (!includeUnstable) {
      versions = versions.where((v) => !v.isUnstable).toList();

      // If no stable versions exist, return null
      if (versions.isEmpty) return null;
    }

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
      antiFeatures: antiFeatures,
      packages: {version.versionCode.toString(): version},
      suggestedVersionName: suggestedVersionName,
      suggestedVersionCode: suggestedVersionCode,
      added: added,
      lastUpdated: lastUpdated,
      featureGraphic: featureGraphic,
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
    List<String>? antiFeatures,
    Map<String, FDroidVersion>? packages,
    String? suggestedVersionName,
    int? suggestedVersionCode,
    DateTime? added,
    DateTime? lastUpdated,
    String? featureGraphic,
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
      antiFeatures: antiFeatures ?? this.antiFeatures,
      packages: packages ?? this.packages,
      suggestedVersionName: suggestedVersionName ?? this.suggestedVersionName,
      suggestedVersionCode: suggestedVersionCode ?? this.suggestedVersionCode,
      added: added ?? this.added,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      featureGraphic: featureGraphic ?? this.featureGraphic,
      repositoryUrl: repositoryUrl ?? this.repositoryUrl,
      availableRepositories:
          availableRepositories ?? this.availableRepositories,
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
  final List<String>? antiFeatures;
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
    this.antiFeatures,
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

  /// Checks if this version is considered unstable (beta, alpha, RC, etc.)
  bool get isUnstable {
    final lowerVersionName = versionName.toLowerCase();
    // Check for common unstable version indicators
    return lowerVersionName.contains('alpha') ||
        lowerVersionName.contains('beta') ||
        lowerVersionName.contains('rc') ||
        lowerVersionName.contains('dev') ||
        lowerVersionName.contains('pre') ||
        lowerVersionName.contains('snapshot') ||
        lowerVersionName.contains('nightly') ||
        lowerVersionName.contains('canary') ||
        lowerVersionName.contains('preview') ||
        lowerVersionName.contains('test');
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

/// Extracts a graphic URL (featureGraphic, promoGraphic, etc.) from the
/// F-Droid index-v2 structure where the value looks like:
/// { "en-US": { "name": "/pkg/en-US/featureGraphic_hash.jpg", "sha256": "...", "size": 123 } }
String? _extractGraphicUrl(dynamic raw, String repoBaseUrl, String? locale) {
  if (raw == null) return null;
  if (raw is! Map) return null;

  // Locale preference order
  final prefs = <String>[];
  if (locale != null && locale.isNotEmpty) {
    prefs.add(locale);
    prefs.add(locale.replaceAll('-', '_'));
    final lang = locale.split('-').first;
    if (lang.isNotEmpty) prefs.add(lang);
  }
  const englishPrefs = ['en-US', 'en', 'en_GB'];
  prefs.addAll(englishPrefs);

  String? extractName(dynamic entry) {
    if (entry is Map && entry['name'] is String) {
      return entry['name'] as String;
    }
    if (entry is String) return entry;
    return null;
  }

  // Try preferred locales first
  for (final key in prefs) {
    final name = extractName(raw[key]);
    if (name != null && name.isNotEmpty) {
      return repoBaseUrl + name;
    }
  }

  // Fallback: any locale
  for (final v in raw.values) {
    final name = extractName(v);
    if (name != null && name.isNotEmpty) {
      return repoBaseUrl + name;
    }
  }

  return null;
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
    String? locale,
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
        final normalizedLocale = locale?.replaceAll('_', '-');

        String extractLocalized(dynamic raw, {String? fallbackKey}) {
          if (raw == null) return '';
          // Plain string
          if (raw is String) return raw;
          if (raw is Map) {
            final localePrefs = <String>[];
            if (normalizedLocale != null && normalizedLocale.isNotEmpty) {
              localePrefs.add(normalizedLocale);
              localePrefs.add(normalizedLocale.replaceAll('-', '_'));

              final language = normalizedLocale.split('-').first;
              if (language.isNotEmpty) {
                localePrefs.add(language);
              }
            }

            // Try exact fallback key first
            if (fallbackKey != null && raw[fallbackKey] is String) {
              return raw[fallbackKey] as String;
            }

            // Try requested locale keys first.
            for (final key in localePrefs) {
              if (raw[key] is String) return raw[key] as String;
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

        List<String>? parseAntiFeatures(dynamic raw) {
          if (raw == null) return null;
          if (raw is List) {
            final values = raw.map((e) {
              if (e is Map) {
                if (e['name'] != null) return e['name'].toString();
                if (e['id'] != null) return e['id'].toString();
              }
              return e.toString();
            }).toList();
            return values.where((e) => e.trim().isNotEmpty).toList();
          }
          if (raw is Map) {
            final values = <String>[];
            raw.forEach((key, value) {
              String? description;
              if (value is Map || value is String) {
                final localized = extractLocalized(value);
                if (localized.trim().isNotEmpty) {
                  description = localized.trim();
                }
              } else if (value != null) {
                final asText = value.toString().trim();
                if (asText.isNotEmpty) {
                  description = asText;
                }
              }

              final keyText = key.toString().trim();
              if (keyText.isEmpty &&
                  (description == null || description.isEmpty)) {
                return;
              }

              if (description != null && description.isNotEmpty) {
                values.add('$keyText: $description');
              } else {
                values.add(keyText);
              }
            });
            return values.isEmpty ? null : values;
          }
          final value = raw.toString().trim();
          return value.isEmpty ? null : <String>[value];
        }

        final Map<String, FDroidVersion> versionObjs = {};
        final versionAntiFeatures = <String>{};
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

            final antiFeatures = parseAntiFeatures(
              versionData['antiFeatures'] ?? versionData['antiFeature'],
            );
            if (antiFeatures != null) {
              versionAntiFeatures.addAll(antiFeatures);
            }

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
              antiFeatures: antiFeatures,
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

        final combinedAntiFeatures = <String>{};
        final metaAntiFeatures = parseAntiFeatures(
          metadata['antiFeatures'] ??
              metadata['antiFeature'] ??
              pkgMap['antiFeatures'] ??
              pkgMap['antiFeature'],
        );
        if (metaAntiFeatures != null) {
          combinedAntiFeatures.addAll(metaAntiFeatures);
        }
        if (versionAntiFeatures.isNotEmpty) {
          combinedAntiFeatures.addAll(versionAntiFeatures);
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
          antiFeatures: combinedAntiFeatures.isEmpty
              ? null
              : combinedAntiFeatures.toList(),
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
          featureGraphic: _extractGraphicUrl(
            metadata['featureGraphic'],
            baseUrl,
            normalizedLocale,
          ),
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
    final normalizedCategory = category.toLowerCase();
    return appsList
        .where(
          (app) =>
              app.categories?.any(
                (appCategory) =>
                    appCategory.toLowerCase() == normalizedCategory,
              ) ??
              false,
        )
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
