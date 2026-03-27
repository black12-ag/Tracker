class AppIdentity {
  AppIdentity._();

  static const String appName = 'Tracker';

  static const String ownerCanonicalEmail = 'muay01111@gmail.com';
  static const String ownerPhoneLocal = '0922380260';
  static const String ownerPhoneIntl = '251922380260';

  static const String contactTelegramHandle = '@muay011';
  static const String contactTelegramUrl = 'https://t.me/muay011';
  static const String contactPhone = '0907806267';

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
