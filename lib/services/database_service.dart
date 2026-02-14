import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/fdroid_app.dart';

class DatabaseService {
  static const String _databaseName = 'fdroid_repository.db';
  static const int _databaseVersion = 4;

  // Table names
  static const String _appsTable = 'apps';
  static const String _versionsTable = 'versions';
  static const String _categoriesTable = 'categories';
  static const String _appCategoriesTable = 'app_categories';
  static const String _metadataTable = 'metadata';
  static const String _repositoriesTable = 'repositories';

  Database? _database;
  String? _currentLocale;

  DatabaseService({String? locale}) : _currentLocale = locale ?? 'en-US';

  /// Gets the database instance, creating it if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates the database schema
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_metadataTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_repositoriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        url TEXT NOT NULL UNIQUE,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        added_at INTEGER,
        last_synced_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $_appsTable (
        package_name TEXT PRIMARY KEY,
        repository_id INTEGER,
        name TEXT NOT NULL,
        summary TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT,
        author_name TEXT,
        author_email TEXT,
        author_website TEXT,
        website TEXT,
        issue_tracker TEXT,
        source_code TEXT,
        changelog TEXT,
        donate TEXT,
        bitcoin TEXT,
        flattr_id TEXT,
        license TEXT NOT NULL,
        suggested_version_name TEXT,
        suggested_version_code INTEGER,
        added INTEGER,
        last_updated INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $_versionsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_name TEXT NOT NULL,
        version_code INTEGER NOT NULL,
        version_name TEXT NOT NULL,
        size INTEGER NOT NULL,
        min_sdk_version TEXT,
        target_sdk_version TEXT,
        max_sdk_version TEXT,
        added INTEGER NOT NULL,
        apk_name TEXT NOT NULL,
        hash TEXT NOT NULL,
        hash_type TEXT NOT NULL,
        sig TEXT,
        permissions TEXT,
        features TEXT,
        nativecode TEXT,
        whats_new TEXT,
        FOREIGN KEY (package_name) REFERENCES $_appsTable (package_name) ON DELETE CASCADE,
        UNIQUE (package_name, version_code)
      )
    ''');

    await db.execute('''
      CREATE TABLE $_categoriesTable (
        category TEXT PRIMARY KEY
      )
    ''');

    await db.execute('''
      CREATE TABLE $_appCategoriesTable (
        package_name TEXT NOT NULL,
        category TEXT NOT NULL,
        PRIMARY KEY (package_name, category),
        FOREIGN KEY (package_name) REFERENCES $_appsTable (package_name) ON DELETE CASCADE,
        FOREIGN KEY (category) REFERENCES $_categoriesTable (category) ON DELETE CASCADE
      )
    ''');

    // Create indices for better query performance
    await db.execute('CREATE INDEX idx_apps_name ON $_appsTable (name)');
    await db.execute('CREATE INDEX idx_apps_added ON $_appsTable (added)');
    await db.execute(
      'CREATE INDEX idx_apps_last_updated ON $_appsTable (last_updated)',
    );
    await db.execute(
      'CREATE INDEX idx_versions_package ON $_versionsTable (package_name)',
    );
    await db.execute(
      'CREATE INDEX idx_app_categories_category ON $_appCategoriesTable (category)',
    );
  }

  /// Handles database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations here
    if (oldVersion < 2) {
      // Create repositories table if upgrading from v1 to v2
      await db.execute('''
        CREATE TABLE $_repositoriesTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          url TEXT NOT NULL UNIQUE,
          is_enabled INTEGER NOT NULL DEFAULT 1,
          added_at INTEGER,
          last_synced_at INTEGER
        )
      ''');
    }
    if (oldVersion < 3) {
      // Add repository_id column to apps table for v2 to v3 upgrade
      await db.execute(
        'ALTER TABLE $_appsTable ADD COLUMN repository_id INTEGER',
      );
    }
    if (oldVersion < 4) {
      // Add whats_new column to versions table for v3 to v4 upgrade
      await db.execute('ALTER TABLE $_versionsTable ADD COLUMN whats_new TEXT');
      // Force re-sync so new field is populated from repository
      await db.delete(
        _metadataTable,
        where: 'key = ?',
        whereArgs: ['last_sync'],
      );
    }
  }

  /// Sets the current locale for localized data extraction
  /// Note: Currently, localized strings are extracted during JSON import
  /// using the FDroidRepository.fromJson method. This locale setting is
  /// reserved for future enhancements to support dynamic locale switching.
  void setLocale(String locale) {
    _currentLocale = locale;
  }

  /// Gets the current locale
  String get currentLocale => _currentLocale ?? 'en-US';

  /// Stores repository metadata
  Future<void> setMetadata(String key, String value) async {
    final db = await database;
    await db.insert(_metadataTable, {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Gets repository metadata
  Future<String?> getMetadata(String key) async {
    final db = await database;
    final results = await db.query(
      _metadataTable,
      where: 'key = ?',
      whereArgs: [key],
    );

    if (results.isEmpty) return null;
    return results.first['value'] as String?;
  }

  /// Checks if the database is populated
  Future<bool> isPopulated() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_appsTable'),
    );
    return (count ?? 0) > 0;
  }

  /// Checks if the database needs update based on timestamp
  Future<bool> needsUpdate(Duration maxAge) async {
    final timestampStr = await getMetadata('last_sync');
    if (timestampStr == null) return true;

    final timestamp = int.tryParse(timestampStr);
    if (timestamp == null) return true;

    final lastSync = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final age = DateTime.now().difference(lastSync);
    return age > maxAge;
  }

  /// Imports repository data from FDroidRepository
  /// If repositoryId is null, clears all existing data (official F-Droid).
  /// If repositoryId is provided, only updates apps from that repository.
  Future<void> importRepository(
    FDroidRepository repository, {
    int? repositoryId,
  }) async {
    final db = await database;

    // Use batch operations for much better performance
    final batch = db.batch();

    // If no repository ID (official F-Droid), clear all data
    if (repositoryId == null) {
      batch.delete(_appCategoriesTable);
      batch.delete(_versionsTable);
      batch.delete(_appsTable);
      batch.delete(_categoriesTable);
    } else {
      // For custom repos, only delete apps from this repository
      batch.delete(
        _appCategoriesTable,
        where:
            '''
          package_name IN (SELECT package_name FROM $_appsTable WHERE repository_id = ?)
        ''',
        whereArgs: [repositoryId],
      );
      batch.delete(
        _versionsTable,
        where:
            '''
          package_name IN (SELECT package_name FROM $_appsTable WHERE repository_id = ?)
        ''',
        whereArgs: [repositoryId],
      );
      batch.delete(
        _appsTable,
        where: 'repository_id = ?',
        whereArgs: [repositoryId],
      );
    }

    // Collect unique categories first
    final uniqueCategories = <String>{};
    for (final app in repository.apps.values) {
      if (app.categories != null) {
        uniqueCategories.addAll(app.categories!);
      }
    }

    // Insert unique categories
    for (final category in uniqueCategories) {
      batch.insert(_categoriesTable, {
        'category': category,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Batch insert apps, versions, and app-category relationships
    for (final app in repository.apps.values) {
      batch.insert(_appsTable, {
        'package_name': app.packageName,
        'repository_id': repositoryId,
        'name': app.name,
        'summary': app.summary,
        'description': app.description,
        'icon': app.icon,
        'author_name': app.authorName,
        'author_email': app.authorEmail,
        'author_website': app.authorWebSite,
        'website': app.webSite,
        'issue_tracker': app.issueTracker,
        'source_code': app.sourceCode,
        'changelog': app.changelog,
        'donate': app.donate,
        'bitcoin': app.bitcoin,
        'flattr_id': app.flattrID,
        'license': app.license,
        'suggested_version_name': app.suggestedVersionName,
        'suggested_version_code': app.suggestedVersionCode,
        'added': app.added?.millisecondsSinceEpoch,
        'last_updated': app.lastUpdated?.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Batch insert versions
      if (app.packages != null) {
        for (final version in app.packages!.values) {
          batch.insert(_versionsTable, {
            'package_name': app.packageName,
            'version_code': version.versionCode,
            'version_name': version.versionName,
            'size': version.size,
            'min_sdk_version': version.minSdkVersion,
            'target_sdk_version': version.targetSdkVersion,
            'max_sdk_version': version.maxSdkVersion,
            'added': version.added.millisecondsSinceEpoch,
            'apk_name': version.apkName,
            'hash': version.hash,
            'hash_type': version.hashType,
            'sig': version.sig,
            'permissions': version.permissions != null
                ? jsonEncode(version.permissions)
                : null,
            'features': version.features != null
                ? jsonEncode(version.features)
                : null,
            'nativecode': version.nativecode != null
                ? jsonEncode(version.nativecode)
                : null,
            'whats_new': version.whatsNew,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Batch insert app-category relationships
      if (app.categories != null) {
        for (final category in app.categories!) {
          batch.insert(_appCategoriesTable, {
            'package_name': app.packageName,
            'category': category,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    }

    // Store metadata
    final now = DateTime.now().millisecondsSinceEpoch;
    batch.insert(_metadataTable, {
      'key': 'last_sync',
      'value': now.toString(),
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert(_metadataTable, {
      'key': 'repo_name',
      'value': repository.name,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert(_metadataTable, {
      'key': 'repo_description',
      'value': repository.description,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Commit all operations at once
    await batch.commit(noResult: true);
  }

  /// Gets all apps from the database
  /// Uses optimized batch loading to avoid N+1 query problem
  Future<List<FDroidApp>> getAllApps() async {
    final db = await database;
    final appMaps = await db.rawQuery('''
      SELECT a.*, r.url as repository_url FROM $_appsTable a
      LEFT JOIN $_repositoriesTable r ON a.repository_id = r.id
    ''');

    if (appMaps.isEmpty) return [];

    // Batch load all categories and versions for all apps at once
    final allCategories = await db.query(_appCategoriesTable);
    final allVersions = await db.query(
      _versionsTable,
      orderBy: 'version_code DESC',
    );

    // Group by package name for efficient lookup
    final categoriesByPackage = <String, List<String>>{};
    for (final catRow in allCategories) {
      final pkg = catRow['package_name'] as String;
      final cat = catRow['category'] as String;
      categoriesByPackage.putIfAbsent(pkg, () => []).add(cat);
    }

    final versionsByPackage = <String, List<Map<String, dynamic>>>{};
    for (final verRow in allVersions) {
      final pkg = verRow['package_name'] as String;
      versionsByPackage.putIfAbsent(pkg, () => []).add(verRow);
    }

    // Build apps with pre-loaded data
    final apps = <FDroidApp>[];
    for (final appMap in appMaps) {
      final packageName = appMap['package_name'] as String;
      final app = _mapToAppWithData(
        appMap,
        categoriesByPackage[packageName] ?? [],
        versionsByPackage[packageName] ?? [],
        repositoryUrl: appMap['repository_url'] as String?,
      );
      apps.add(app);
    }

    return apps;
  }

  /// Gets latest apps ordered by added date
  Future<List<FDroidApp>> getLatestApps({int limit = 50}) async {
    final db = await database;
    final appMaps = await db.rawQuery(
      '''
      SELECT a.*, r.url as repository_url FROM $_appsTable a
      LEFT JOIN $_repositoriesTable r ON a.repository_id = r.id
      WHERE a.added IS NOT NULL
      ORDER BY a.added DESC
      LIMIT ?
    ''',
      [limit],
    );

    // Get package names from the limited result set
    final packageNames = appMaps
        .map((m) => m['package_name'] as String)
        .toList();

    if (packageNames.isEmpty) return [];

    // Batch load categories and versions for these specific apps
    final categoriesResults = await db.query(
      _appCategoriesTable,
      where:
          'package_name IN (${List.filled(packageNames.length, '?').join(',')})',
      whereArgs: packageNames,
    );

    final versionsResults = await db.query(
      _versionsTable,
      where:
          'package_name IN (${List.filled(packageNames.length, '?').join(',')})',
      whereArgs: packageNames,
      orderBy: 'version_code DESC',
    );

    // Group by package name
    final categoriesByPackage = <String, List<String>>{};
    for (final catRow in categoriesResults) {
      final pkg = catRow['package_name'] as String;
      final cat = catRow['category'] as String;
      categoriesByPackage.putIfAbsent(pkg, () => []).add(cat);
    }

    final versionsByPackage = <String, List<Map<String, dynamic>>>{};
    for (final verRow in versionsResults) {
      final pkg = verRow['package_name'] as String;
      versionsByPackage.putIfAbsent(pkg, () => []).add(verRow);
    }

    final apps = <FDroidApp>[];
    for (final appMap in appMaps) {
      final packageName = appMap['package_name'] as String;
      final app = _mapToAppWithData(
        appMap,
        categoriesByPackage[packageName] ?? [],
        versionsByPackage[packageName] ?? [],
        repositoryUrl: appMap['repository_url'] as String?,
      );
      apps.add(app);
    }

    return apps;
  }

  /// Gets all categories
  Future<List<String>> getCategories() async {
    final db = await database;
    final results = await db.query(_categoriesTable, orderBy: 'category ASC');

    return results.map((row) => row['category'] as String).toList();
  }

  /// Gets apps by category
  Future<List<FDroidApp>> getAppsByCategory(String category) async {
    final db = await database;
    final appMaps = await db.rawQuery(
      '''
      SELECT a.*, r.url as repository_url FROM $_appsTable a
      LEFT JOIN $_repositoriesTable r ON a.repository_id = r.id
      INNER JOIN $_appCategoriesTable ac ON a.package_name = ac.package_name
      WHERE ac.category = ?
      ORDER BY a.name ASC
    ''',
      [category],
    );

    if (appMaps.isEmpty) return [];

    // Get package names from the result set
    final packageNames = appMaps
        .map((m) => m['package_name'] as String)
        .toList();

    // Batch load all categories and versions for these apps
    final categoriesResults = await db.query(
      _appCategoriesTable,
      where:
          'package_name IN (${List.filled(packageNames.length, '?').join(',')})',
      whereArgs: packageNames,
    );

    final versionsResults = await db.query(
      _versionsTable,
      where:
          'package_name IN (${List.filled(packageNames.length, '?').join(',')})',
      whereArgs: packageNames,
      orderBy: 'version_code DESC',
    );

    // Group by package name
    final categoriesByPackage = <String, List<String>>{};
    for (final catRow in categoriesResults) {
      final pkg = catRow['package_name'] as String;
      final cat = catRow['category'] as String;
      categoriesByPackage.putIfAbsent(pkg, () => []).add(cat);
    }

    final versionsByPackage = <String, List<Map<String, dynamic>>>{};
    for (final verRow in versionsResults) {
      final pkg = verRow['package_name'] as String;
      versionsByPackage.putIfAbsent(pkg, () => []).add(verRow);
    }

    final apps = <FDroidApp>[];
    for (final appMap in appMaps) {
      final packageName = appMap['package_name'] as String;
      final app = _mapToAppWithData(
        appMap,
        categoriesByPackage[packageName] ?? [],
        versionsByPackage[packageName] ?? [],
        repositoryUrl: appMap['repository_url'] as String?,
      );
      apps.add(app);
    }

    return apps;
  }

  /// Searches apps by repository URL
  Future<List<FDroidApp>> searchAppsByRepository(
    String query,
    String repositoryUrl,
  ) async {
    final db = await database;

    // Get repository ID by URL
    final repoResults = await db.query(
      _repositoriesTable,
      where: 'url = ?',
      whereArgs: [repositoryUrl],
    );

    if (repoResults.isEmpty) {
      return []; // Repository not found in database
    }

    final repositoryId = repoResults.first['id'] as int;
    final searchTerm = '%${query.toLowerCase()}%';
    final exactQuery = query.toLowerCase();
    final startsWithTerm = '${query.toLowerCase()}%';
    final normalizedQuery = query.toLowerCase().replaceAll('-', '');
    final normalizedTerm = '%$normalizedQuery%';

    // Search apps from this specific repository with weighted scoring
    final appMaps = await db.rawQuery(
      '''
      SELECT DISTINCT a.*, r.url as repository_url,
        CASE
          WHEN LOWER(a.name) = ? THEN 10000
          WHEN REPLACE(LOWER(a.name), '-', '') = ? THEN 9000
          WHEN LOWER(a.name) LIKE ? THEN 5000
          WHEN REPLACE(LOWER(a.name), '-', '') LIKE ? THEN 3000
          WHEN LOWER(a.name) LIKE ? THEN 1000
          WHEN LOWER(a.summary) LIKE ? THEN 100
          WHEN REPLACE(LOWER(a.summary), '-', '') LIKE ? THEN 75
          WHEN LOWER(a.description) LIKE ? THEN 50
          WHEN REPLACE(LOWER(a.description), '-', '') LIKE ? THEN 40
          WHEN EXISTS (
            SELECT 1 FROM $_appCategoriesTable ac 
            WHERE ac.package_name = a.package_name 
            AND LOWER(ac.category) LIKE ?
          ) THEN 25
          WHEN LOWER(a.package_name) LIKE ? THEN 10
          WHEN REPLACE(LOWER(a.package_name), '-', '') LIKE ? THEN 8
          ELSE 1
        END as search_score
      FROM $_appsTable a
      LEFT JOIN $_repositoriesTable r ON a.repository_id = r.id
      LEFT JOIN $_appCategoriesTable ac ON a.package_name = ac.package_name
      WHERE a.repository_id = ?
        AND (LOWER(a.name) LIKE ? 
         OR REPLACE(LOWER(a.name), '-', '') LIKE ?
         OR LOWER(a.summary) LIKE ? 
         OR REPLACE(LOWER(a.summary), '-', '') LIKE ?
         OR LOWER(a.description) LIKE ?
         OR REPLACE(LOWER(a.description), '-', '') LIKE ?
         OR LOWER(a.package_name) LIKE ?
         OR REPLACE(LOWER(a.package_name), '-', '') LIKE ?
         OR LOWER(ac.category) LIKE ?)
      ORDER BY search_score DESC, a.name ASC
    ''',
      [
        exactQuery,
        normalizedQuery,
        startsWithTerm,
        normalizedTerm,
        searchTerm,
        searchTerm,
        normalizedTerm,
        searchTerm,
        normalizedTerm,
        searchTerm,
        searchTerm,
        normalizedTerm,
        repositoryId,
        searchTerm,
        normalizedTerm,
        searchTerm,
        normalizedTerm,
        searchTerm,
        normalizedTerm,
        searchTerm,
        normalizedTerm,
        searchTerm,
      ],
    );

    if (appMaps.isEmpty) return [];

    // Get package names from the result set
    final packageNames = appMaps
        .map((m) => m['package_name'] as String)
        .toList();

    // Batch load all categories and versions for these apps
    final categoriesResults = await db.query(
      _appCategoriesTable,
      where:
          'package_name IN (${List.filled(packageNames.length, '?').join(',')})',
      whereArgs: packageNames,
    );

    final versionsResults = await db.query(
      _versionsTable,
      where:
          'package_name IN (${List.filled(packageNames.length, '?').join(',')})',
      whereArgs: packageNames,
      orderBy: 'version_code DESC',
    );

    // Group by package name
    final categoriesByPackage = <String, List<String>>{};
    for (final catRow in categoriesResults) {
      final pkg = catRow['package_name'] as String;
      final cat = catRow['category'] as String;
      categoriesByPackage.putIfAbsent(pkg, () => []).add(cat);
    }

    final versionsByPackage = <String, List<Map<String, dynamic>>>{};
    for (final verRow in versionsResults) {
      final pkg = verRow['package_name'] as String;
      versionsByPackage.putIfAbsent(pkg, () => []).add(verRow);
    }

    final apps = <FDroidApp>[];
    for (final appMap in appMaps) {
      final packageName = appMap['package_name'] as String;
      final app = _mapToAppWithData(
        appMap,
        categoriesByPackage[packageName] ?? [],
        versionsByPackage[packageName] ?? [],
        repositoryUrl: appMap['repository_url'] as String?,
      );
      apps.add(app);
    }

    return apps;
  }

  /// Searches apps by name, summary, description, or package name
  Future<List<FDroidApp>> searchApps(String query) async {
    final db = await database;
    final searchTerm = '%${query.toLowerCase()}%';
    final exactQuery = query.toLowerCase();
    final startsWithTerm = '${query.toLowerCase()}%';
    final normalizedQuery = query.toLowerCase().replaceAll('-', '');
    final normalizedTerm = '%$normalizedQuery%';
    final appMaps = await db.rawQuery(
      '''
      SELECT DISTINCT a.*, r.url as repository_url,
        CASE
          WHEN LOWER(a.name) = ? THEN 10000
          WHEN REPLACE(LOWER(a.name), '-', '') = ? THEN 9000
          WHEN LOWER(a.name) LIKE ? THEN 5000
          WHEN REPLACE(LOWER(a.name), '-', '') LIKE ? THEN 3000
          WHEN LOWER(a.name) LIKE ? THEN 1000
          WHEN LOWER(a.summary) LIKE ? THEN 100
          WHEN REPLACE(LOWER(a.summary), '-', '') LIKE ? THEN 75
          WHEN LOWER(a.description) LIKE ? THEN 50
          WHEN REPLACE(LOWER(a.description), '-', '') LIKE ? THEN 40
          WHEN EXISTS (
            SELECT 1 FROM $_appCategoriesTable ac 
            WHERE ac.package_name = a.package_name 
            AND LOWER(ac.category) LIKE ?
          ) THEN 25
          WHEN LOWER(a.package_name) LIKE ? THEN 10
          WHEN REPLACE(LOWER(a.package_name), '-', '') LIKE ? THEN 8
          ELSE 1
        END as search_score
      FROM $_appsTable a
      LEFT JOIN $_repositoriesTable r ON a.repository_id = r.id
      LEFT JOIN $_appCategoriesTable ac ON a.package_name = ac.package_name
      WHERE LOWER(a.name) LIKE ? 
         OR REPLACE(LOWER(a.name), '-', '') LIKE ?
         OR LOWER(a.summary) LIKE ? 
         OR REPLACE(LOWER(a.summary), '-', '') LIKE ?
         OR LOWER(a.description) LIKE ?
         OR REPLACE(LOWER(a.description), '-', '') LIKE ?
         OR LOWER(a.package_name) LIKE ?
         OR REPLACE(LOWER(a.package_name), '-', '') LIKE ?
         OR LOWER(ac.category) LIKE ?
      ORDER BY search_score DESC, a.name ASC
    ''',
      [
        exactQuery,
        normalizedQuery,
        startsWithTerm,
        normalizedTerm,
        searchTerm,
        searchTerm,
        normalizedTerm,
        searchTerm,
        normalizedTerm,
        searchTerm,
        searchTerm,
        normalizedTerm,
        searchTerm,
        normalizedTerm,
        searchTerm,
        normalizedTerm,
        searchTerm,
        normalizedTerm,
        searchTerm,
        searchTerm,
      ],
    );

    if (appMaps.isEmpty) return [];

    // Get package names from the result set
    final packageNames = appMaps
        .map((m) => m['package_name'] as String)
        .toList();

    // Batch load all categories and versions for these apps
    final categoriesResults = await db.query(
      _appCategoriesTable,
      where:
          'package_name IN (${List.filled(packageNames.length, '?').join(',')})',
      whereArgs: packageNames,
    );

    final versionsResults = await db.query(
      _versionsTable,
      where:
          'package_name IN (${List.filled(packageNames.length, '?').join(',')})',
      whereArgs: packageNames,
      orderBy: 'version_code DESC',
    );

    // Group by package name
    final categoriesByPackage = <String, List<String>>{};
    for (final catRow in categoriesResults) {
      final pkg = catRow['package_name'] as String;
      final cat = catRow['category'] as String;
      categoriesByPackage.putIfAbsent(pkg, () => []).add(cat);
    }

    final versionsByPackage = <String, List<Map<String, dynamic>>>{};
    for (final verRow in versionsResults) {
      final pkg = verRow['package_name'] as String;
      versionsByPackage.putIfAbsent(pkg, () => []).add(verRow);
    }

    final apps = <FDroidApp>[];
    for (final appMap in appMaps) {
      final packageName = appMap['package_name'] as String;
      final app = _mapToAppWithData(
        appMap,
        categoriesByPackage[packageName] ?? [],
        versionsByPackage[packageName] ?? [],
        repositoryUrl: appMap['repository_url'] as String?,
      );
      apps.add(app);
    }

    return apps;
  }

  /// Gets a specific app by package name
  Future<FDroidApp?> getApp(String packageName) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT a.*, r.url as repository_url FROM $_appsTable a
      LEFT JOIN $_repositoriesTable r ON a.repository_id = r.id
      WHERE a.package_name = ?
    ''',
      [packageName],
    );

    if (results.isEmpty) return null;
    return await _mapToApp(results.first);
  }

  /// Converts a database row to an FDroidApp with pre-loaded data
  /// This version accepts pre-loaded categories and versions to avoid N+1 queries
  FDroidApp _mapToAppWithData(
    Map<String, dynamic> appMap,
    List<String> categories,
    List<Map<String, dynamic>> versionMaps, {
    String? repositoryUrl,
  }) {
    final packages = <String, FDroidVersion>{};
    for (final versionMap in versionMaps) {
      final version = FDroidVersion(
        versionCode: versionMap['version_code'] as int,
        versionName: versionMap['version_name'] as String,
        size: versionMap['size'] as int,
        minSdkVersion: versionMap['min_sdk_version'] as String?,
        targetSdkVersion: versionMap['target_sdk_version'] as String?,
        maxSdkVersion: versionMap['max_sdk_version'] as String?,
        added: DateTime.fromMillisecondsSinceEpoch(versionMap['added'] as int),
        apkName: versionMap['apk_name'] as String,
        hash: versionMap['hash'] as String,
        hashType: versionMap['hash_type'] as String,
        sig: versionMap['sig'] as String?,
        permissions: versionMap['permissions'] != null
            ? List<String>.from(jsonDecode(versionMap['permissions'] as String))
            : null,
        features: versionMap['features'] != null
            ? List<String>.from(jsonDecode(versionMap['features'] as String))
            : null,
        nativecode: versionMap['nativecode'] != null
            ? List<String>.from(jsonDecode(versionMap['nativecode'] as String))
            : null,
        whatsNew: versionMap['whats_new'] as String?,
      );
      packages[version.versionCode.toString()] = version;
    }

    return FDroidApp(
      packageName: appMap['package_name'] as String,
      name: appMap['name'] as String,
      summary: appMap['summary'] as String,
      description: appMap['description'] as String,
      icon: appMap['icon'] as String?,
      authorName: appMap['author_name'] as String?,
      authorEmail: appMap['author_email'] as String?,
      authorWebSite: appMap['author_website'] as String?,
      webSite: appMap['website'] as String?,
      issueTracker: appMap['issue_tracker'] as String?,
      sourceCode: appMap['source_code'] as String?,
      changelog: appMap['changelog'] as String?,
      donate: appMap['donate'] as String?,
      bitcoin: appMap['bitcoin'] as String?,
      flattrID: appMap['flattr_id'] as String?,
      license: appMap['license'] as String,
      categories: categories.isEmpty ? null : categories,
      packages: packages.isEmpty ? null : packages,
      suggestedVersionName: appMap['suggested_version_name'] as String?,
      suggestedVersionCode: appMap['suggested_version_code'] as int?,
      added: appMap['added'] != null
          ? DateTime.fromMillisecondsSinceEpoch(appMap['added'] as int)
          : null,
      lastUpdated: appMap['last_updated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(appMap['last_updated'] as int)
          : null,
      repositoryUrl: repositoryUrl ?? 'https://f-droid.org/repo',
    );
  }

  /// Converts a database row to an FDroidApp (for single app queries)
  /// This version makes individual queries for categories and versions
  Future<FDroidApp> _mapToApp(Map<String, dynamic> appMap) async {
    final packageName = appMap['package_name'] as String;

    // Get categories
    final db = await database;
    final categoryResults = await db.query(
      _appCategoriesTable,
      where: 'package_name = ?',
      whereArgs: [packageName],
    );
    final categories = categoryResults
        .map((row) => row['category'] as String)
        .toList();

    // Get versions
    final versionResults = await db.query(
      _versionsTable,
      where: 'package_name = ?',
      whereArgs: [packageName],
      orderBy: 'version_code DESC',
    );

    return _mapToAppWithData(
      appMap,
      categories,
      versionResults,
      repositoryUrl: appMap['repository_url'] as String?,
    );
  }

  /// Closes the database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Clears all database data
  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_appCategoriesTable);
      await txn.delete(_versionsTable);
      await txn.delete(_appsTable);
      await txn.delete(_categoriesTable);
      await txn.delete(_metadataTable);
    });
  }

  // Repository management methods

  /// Adds a new repository
  Future<int> addRepository(String name, String url) async {
    final db = await database;
    return await db.insert(_repositoriesTable, {
      'name': name,
      'url': url,
      'is_enabled': 1,
      'added_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Gets all repositories
  Future<List<Map<String, dynamic>>> getAllRepositories() async {
    final db = await database;
    return await db.query(_repositoriesTable, orderBy: 'added_at DESC');
  }

  /// Updates a repository
  Future<int> updateRepository(
    int id,
    String name,
    String url,
    bool isEnabled,
  ) async {
    final db = await database;
    return await db.update(
      _repositoriesTable,
      {'name': name, 'url': url, 'is_enabled': isEnabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a repository
  Future<int> deleteRepository(int id) async {
    final db = await database;
    return await db.delete(
      _repositoriesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Updates the last synced timestamp for a repository
  Future<int> updateRepositoryLastSynced(int id) async {
    final db = await database;
    return await db.update(
      _repositoriesTable,
      {'last_synced_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Gets enabled repositories
  Future<List<Map<String, dynamic>>> getEnabledRepositories() async {
    final db = await database;
    return await db.query(
      _repositoriesTable,
      where: 'is_enabled = 1',
      orderBy: 'added_at DESC',
    );
  }
}
