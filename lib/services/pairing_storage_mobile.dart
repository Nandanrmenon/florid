/// Mobile implementation - uses in-memory storage only
/// For actual cross-device communication, a server backend is required
class PairingStorage {
  /// Save messages (no-op on mobile, uses in-memory queue)
  static void saveMessages(String code, String messagesJson) {
    // Mobile uses in-memory queue only
    // For production, implement server API calls here
  }

  /// Load messages (returns null on mobile, uses in-memory queue)
  static String? loadMessages(String code) {
    // Mobile uses in-memory queue only
    // For production, implement server API calls here
    return null;
  }

  /// Clear all messages
  static void clearAllMessages() {
    // Mobile uses in-memory queue only
  }
}
