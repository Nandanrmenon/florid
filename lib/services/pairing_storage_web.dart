import 'dart:html' as html;

/// Web implementation using localStorage for cross-tab communication
class PairingStorage {
  static const String _keyPrefix = 'florid_pairing_messages_';

  /// Save messages to localStorage
  static void saveMessages(String code, String messagesJson) {
    try {
      html.window.localStorage['$_keyPrefix$code'] = messagesJson;
    } catch (e) {
      print('[PairingStorage] Error saving to localStorage: $e');
    }
  }

  /// Load messages from localStorage
  static String? loadMessages(String code) {
    try {
      return html.window.localStorage['$_keyPrefix$code'];
    } catch (e) {
      print('[PairingStorage] Error loading from localStorage: $e');
      return null;
    }
  }

  /// Clear all pairing messages from localStorage
  static void clearAllMessages() {
    try {
      final keys = html.window.localStorage.keys.toList();
      for (final key in keys) {
        if (key.startsWith(_keyPrefix)) {
          html.window.localStorage.remove(key);
        }
      }
    } catch (e) {
      print('[PairingStorage] Error clearing localStorage: $e');
    }
  }
}
