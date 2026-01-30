/// Stub implementation for pairing storage
/// This is the default that gets imported when neither web nor mobile platforms are detected
class PairingStorage {
  /// Save messages to storage
  static void saveMessages(String code, String messagesJson) {
    // Stub implementation - does nothing
  }

  /// Load messages from storage
  static String? loadMessages(String code) {
    // Stub implementation - returns null
    return null;
  }

  /// Clear all messages
  static void clearAllMessages() {
    // Stub implementation - does nothing
  }
}
