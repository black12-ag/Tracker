class AppIdentity {
  AppIdentity._();

  static const String appName = 'Tracker';

  static const String ownerCanonicalEmail = '';
  static const String ownerPhoneLocal = '';
  static const String ownerPhoneIntl = '';

  static const String contactTelegramHandle = '';
  static const String contactTelegramUrl = '';
  static const String contactPhone = '';

  static const String splashSeenKey = 'hasShown3DSplash';

  static String normalizePhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('251') && digits.length == 12) {
      return digits;
    }

    if (digits.startsWith('0') && digits.length == 10) {
      return '251${digits.substring(1)}';
    }

    return digits;
  }

  static bool looksLikePhone(String value) {
    final digits = normalizePhone(value);
    return digits.length >= 10 && !value.contains('@');
  }

  static String phoneToSyntheticEmail(String value) {
    final normalized = normalizePhone(value);
    return 'staff-$normalized@tracker.local';
  }

  static String normalizeLoginIdentifier(String value) {
    final trimmed = value.trim();
    final digits = normalizePhone(trimmed);
    if (digits == ownerPhoneIntl || digits == normalizePhone(ownerPhoneLocal)) {
      return ownerCanonicalEmail;
    }

    if (looksLikePhone(trimmed)) {
      return phoneToSyntheticEmail(trimmed);
    }

    return trimmed.toLowerCase();
  }
}
