class OfflineErrorDetector {
  static bool isLikelyOffline(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection closed') ||
        message.contains('network is unreachable') ||
        message.contains('connection refused') ||
        message.contains('timeout') ||
        message.contains('clientexception') ||
        message.contains('handshake') ||
        message.contains('certificate') ||
        message.contains('503') ||
        message.contains('project is paused') ||
        message.contains('service unavailable');
  }
}
