import 'package:flutter/foundation.dart';

import '../models/repository.dart';
import '../services/database_service.dart';

class RepositoriesProvider extends ChangeNotifier {
  final DatabaseService _databaseService;

  RepositoriesProvider(this._databaseService);

  List<Repository> _repositories = [];
  bool _isLoading = false;
  String? _error;

  List<Repository> get repositories => _repositories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads all repositories from database
  Future<void> loadRepositories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final maps = await _databaseService.getAllRepositories();
      _repositories = maps.map((map) => Repository.fromMap(map)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading repositories: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Adds a new repository
  Future<void> addRepository(String name, String url) async {
    _error = null;
    try {
      // Validate URL format
      if (!_isValidUrl(url)) {
        _error = 'Invalid URL format';
        notifyListeners();
        return;
      }

      // Check if URL already exists
      if (_repositories.any((r) => r.url == url)) {
        _error = 'This repository URL already exists';
        notifyListeners();
        return;
      }

      final id = await _databaseService.addRepository(name, url);
      _repositories.add(
        Repository(
          id: id,
          name: name,
          url: url,
          isEnabled: true,
          addedAt: DateTime.now(),
        ),
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding repository: $e');
      notifyListeners();
    }
  }

  /// Updates a repository
  Future<void> updateRepository(
    int id,
    String name,
    String url,
    bool isEnabled,
  ) async {
    _error = null;
    try {
      // Validate URL format
      if (!_isValidUrl(url)) {
        _error = 'Invalid URL format';
        notifyListeners();
        return;
      }

      // Check if URL already exists (excluding current repository)
      if (_repositories.any((r) => r.url == url && r.id != id)) {
        _error = 'This repository URL already exists';
        notifyListeners();
        return;
      }

      await _databaseService.updateRepository(id, name, url, isEnabled);

      final index = _repositories.indexWhere((r) => r.id == id);
      if (index != -1) {
        _repositories[index] = _repositories[index].copyWith(
          name: name,
          url: url,
          isEnabled: isEnabled,
        );
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating repository: $e');
      notifyListeners();
    }
  }

  /// Deletes a repository
  Future<void> deleteRepository(int id) async {
    _error = null;
    try {
      await _databaseService.deleteRepository(id);
      _repositories.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting repository: $e');
      notifyListeners();
    }
  }

  /// Toggles repository enabled/disabled state
  Future<void> toggleRepository(int id) async {
    final index = _repositories.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final repo = _repositories[index];
    await updateRepository(id, repo.name, repo.url, !repo.isEnabled);
  }

  /// Clears the error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Validates URL format
  bool _isValidUrl(String url) {
    try {
      Uri.parse(url);
      return url.startsWith('http://') || url.startsWith('https://');
    } catch (_) {
      return false;
    }
  }

  /// Gets only enabled repositories
  List<Repository> get enabledRepositories =>
      _repositories.where((r) => r.isEnabled).toList();

  /// Gets the default F-Droid repository URL
  static const String defaultFDroidUrl = 'https://f-droid.org';
}
