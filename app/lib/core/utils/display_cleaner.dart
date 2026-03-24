class DisplayCleaner {
  DisplayCleaner._();

  static final RegExp _technicalPattern = RegExp(
    r'(verify-|local-|archived-|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})',
    caseSensitive: false,
  );

  static String customerName(String? value, {String fallback = 'Customer'}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return fallback;
    }
    if (trimmed.toLowerCase().startsWith('verify customer') ||
        _technicalPattern.hasMatch(trimmed)) {
      return fallback;
    }
    return trimmed;
  }

  static String? note(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    if (_technicalPattern.hasMatch(trimmed)) {
      return null;
    }
    return trimmed;
  }

  static String status(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'partial':
        return 'Part paid';
      case 'unpaid':
        return 'Not paid';
      case 'recorded':
        return 'Saved';
      default:
        return 'Open';
    }
  }
}
