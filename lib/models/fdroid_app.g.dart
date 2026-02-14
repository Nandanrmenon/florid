// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fdroid_app.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FDroidApp _$FDroidAppFromJson(Map<String, dynamic> json) => FDroidApp(
  packageName: json['packageName'] as String,
  name: json['name'] as String,
  summary: json['summary'] as String,
  description: json['description'] as String,
  icon: json['icon'] as String?,
  authorName: json['authorName'] as String?,
  authorEmail: json['authorEmail'] as String?,
  authorWebSite: json['authorWebSite'] as String?,
  webSite: json['webSite'] as String?,
  issueTracker: json['issueTracker'] as String?,
  sourceCode: json['sourceCode'] as String?,
  changelog: json['changelog'] as String?,
  donate: json['donate'] as String?,
  bitcoin: json['bitcoin'] as String?,
  flattrID: json['flattrID'] as String?,
  license: json['license'] as String,
  categories: (json['categories'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  antiFeatures: (json['antiFeatures'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  packages: (json['packages'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, FDroidVersion.fromJson(e as Map<String, dynamic>)),
  ),
  suggestedVersionName: json['suggestedVersionName'] as String?,
  suggestedVersionCode: (json['suggestedVersionCode'] as num?)?.toInt(),
  added: json['added'] == null ? null : DateTime.parse(json['added'] as String),
  lastUpdated: json['lastUpdated'] == null
      ? null
      : DateTime.parse(json['lastUpdated'] as String),
);

Map<String, dynamic> _$FDroidAppToJson(FDroidApp instance) => <String, dynamic>{
  'packageName': instance.packageName,
  'name': instance.name,
  'summary': instance.summary,
  'description': instance.description,
  'icon': instance.icon,
  'authorName': instance.authorName,
  'authorEmail': instance.authorEmail,
  'authorWebSite': instance.authorWebSite,
  'webSite': instance.webSite,
  'issueTracker': instance.issueTracker,
  'sourceCode': instance.sourceCode,
  'changelog': instance.changelog,
  'donate': instance.donate,
  'bitcoin': instance.bitcoin,
  'flattrID': instance.flattrID,
  'license': instance.license,
  'categories': instance.categories,
  'antiFeatures': instance.antiFeatures,
  'packages': instance.packages,
  'suggestedVersionName': instance.suggestedVersionName,
  'suggestedVersionCode': instance.suggestedVersionCode,
  'added': instance.added?.toIso8601String(),
  'lastUpdated': instance.lastUpdated?.toIso8601String(),
};

FDroidVersion _$FDroidVersionFromJson(Map<String, dynamic> json) =>
    FDroidVersion(
      versionCode: (json['versionCode'] as num).toInt(),
      versionName: json['versionName'] as String,
      size: (json['size'] as num).toInt(),
      minSdkVersion: json['minSdkVersion'] as String?,
      targetSdkVersion: json['targetSdkVersion'] as String?,
      maxSdkVersion: json['maxSdkVersion'] as String?,
      added: DateTime.parse(json['added'] as String),
      apkName: json['apkName'] as String,
      hash: json['hash'] as String,
      hashType: json['hashType'] as String,
      sig: json['sig'] as String?,
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      antiFeatures: (json['antiFeatures'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      nativecode: (json['nativecode'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      whatsNew: json['whatsNew'] as String?,
    );

Map<String, dynamic> _$FDroidVersionToJson(FDroidVersion instance) =>
    <String, dynamic>{
      'versionCode': instance.versionCode,
      'versionName': instance.versionName,
      'size': instance.size,
      'minSdkVersion': instance.minSdkVersion,
      'targetSdkVersion': instance.targetSdkVersion,
      'maxSdkVersion': instance.maxSdkVersion,
      'added': instance.added.toIso8601String(),
      'apkName': instance.apkName,
      'hash': instance.hash,
      'hashType': instance.hashType,
      'sig': instance.sig,
      'permissions': instance.permissions,
      'features': instance.features,
      'antiFeatures': instance.antiFeatures,
      'nativecode': instance.nativecode,
      'whatsNew': instance.whatsNew,
    };

FDroidCategory _$FDroidCategoryFromJson(Map<String, dynamic> json) =>
    FDroidCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      appCount: (json['appCount'] as num).toInt(),
    );

Map<String, dynamic> _$FDroidCategoryToJson(FDroidCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'appCount': instance.appCount,
    };

FDroidRepository _$FDroidRepositoryFromJson(Map<String, dynamic> json) =>
    FDroidRepository(
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      timestamp: json['timestamp'] as String,
      version: json['version'] as String,
      maxage: (json['maxage'] as num).toInt(),
      apps: (json['apps'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, FDroidApp.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$FDroidRepositoryToJson(FDroidRepository instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'icon': instance.icon,
      'timestamp': instance.timestamp,
      'version': instance.version,
      'maxage': instance.maxage,
      'apps': instance.apps,
    };
